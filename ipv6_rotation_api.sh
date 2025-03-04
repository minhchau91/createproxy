#!/usr/bin/env python3
from flask import Flask, request, jsonify
import subprocess
import os
import time
import json
import logging
import random
import shutil
from functools import wraps

# Thiết lập logging
logging.basicConfig(
    filename='/var/log/ipv6_rotation_api.log',
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

# Thêm log ra console
console = logging.StreamHandler()
console.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
console.setFormatter(formatter)
logging.getLogger('').addHandler(console)

app = Flask(__name__)

# Khóa API đơn giản để bảo vệ API
API_KEY = "f69ea957-a908-4fe3-917f-577135f195f8"  # Thay đổi giá trị này!

# Đường dẫn file cấu hình
CONFIG_FILE = "/usr/local/etc/3proxy/3proxy.cfg"
BACKUP_FILE = "/usr/local/etc/3proxy/3proxy.cfg.bak"
DATA_FILE = "/home/proxy-installer/data.txt"
SUBNET_FILE = "/home/proxy-installer/ipv6-subnet.txt"
PID_FILE = "/var/run/3proxy.pid"  # File PID của 3proxy

# Decorator để kiểm tra API key
def require_api_key(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        key = request.headers.get('X-API-Key')
        if key and key == API_KEY:
            return f(*args, **kwargs)
        logging.warning(f"Unauthorized access attempt from {request.remote_addr}")
        return jsonify({"success": False, "message": "Unauthorized"}), 401
    return decorated

# Hàm gọi lệnh shell và trả về output
def run_command(command):
    logging.info(f"Executing command: {command}")
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    stdout, stderr = process.communicate()
    return stdout.decode('utf-8'), stderr.decode('utf-8'), process.returncode

# Hàm tạo IPv6 mới
def gen_ipv6(subnet, prefix):
    logging.debug(f"Generating new IPv6 for subnet {subnet} with prefix {prefix}")
    
    array = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "a", "b", "c", "d", "e", "f"]
    filename = f"/root/{subnet}.txt"
    
    # Tạo file nếu chưa tồn tại
    if not os.path.exists(filename):
        open(filename, 'a').close()
    
    # Hàm tạo 4 ký tự hex ngẫu nhiên
    def random4():
        return ''.join(random.choice(array) for _ in range(4))
    
    # Hàm tạo 2 ký tự hex ngẫu nhiên
    def random2():
        return ''.join(random.choice(array) for _ in range(2))
    
    # Tạo IPv6 dựa trên prefix
    if prefix in ["64", "48"]:
        if prefix == "64":
            while True:
                ipv6 = f"{subnet}:{random4()}:{random4()}:{random4()}:{random4()}"
                # Kiểm tra xem IPv6 đã tồn tại chưa
                with open(filename, 'r') as f:
                    if ipv6 not in f.read():
                        break
                # Ghi IPv6 trùng vào file
                with open("/root/duplicateipv6.txt", 'a') as f:
                    f.write(f"{ipv6}\n")
        else:  # prefix == "48"
            while True:
                ipv6 = f"{subnet}:{random4()}:{random4()}:{random4()}:{random4()}:{random4()}"
                with open(filename, 'r') as f:
                    if ipv6 not in f.read():
                        break
                with open("/root/duplicateipv6.txt", 'a') as f:
                    f.write(f"{ipv6}\n")
    else:
        if prefix == "56":
            while True:
                ipv6 = f"{subnet}{random2()}:{random4()}:{random4()}:{random4()}:{random4()}"
                with open(filename, 'r') as f:
                    if ipv6 not in f.read():
                        break
                with open("/root/duplicateipv6.txt", 'a') as f:
                    f.write(f"{ipv6}\n")
        else:
            while True:
                ipv6 = f"{subnet}:{random4()}:{random4()}:{random4()}:{random4()}:{random4()}:{random4()}"
                with open(filename, 'r') as f:
                    if ipv6 not in f.read():
                        break
                with open("/root/duplicateipv6.txt", 'a') as f:
                    f.write(f"{ipv6}\n")
    
    # Ghi IPv6 mới vào file
    with open(filename, 'a') as f:
        f.write(f"{ipv6}\n")
    
    logging.debug(f"Generated IPv6: {ipv6}")
    return ipv6

# Hàm sao lưu file cấu hình
def backup_config():
    try:
        if os.path.exists(CONFIG_FILE):
            shutil.copy2(CONFIG_FILE, BACKUP_FILE)
            logging.info(f"Backed up config file to {BACKUP_FILE}")
            return True
        else:
            logging.error(f"Config file {CONFIG_FILE} does not exist")
            return False
    except Exception as e:
        logging.error(f"Failed to backup config: {str(e)}")
        return False

# Hàm khôi phục file cấu hình từ backup
def restore_config():
    try:
        if os.path.exists(BACKUP_FILE):
            shutil.copy2(BACKUP_FILE, CONFIG_FILE)
            logging.info(f"Restored config from {BACKUP_FILE}")
            return True
        else:
            logging.error(f"Backup file {BACKUP_FILE} does not exist")
            return False
    except Exception as e:
        logging.error(f"Failed to restore config: {str(e)}")
        return False

# Hàm kiểm tra cú pháp file cấu hình
# def check_config_syntax():
#     cmd = f"/usr/local/etc/3proxy/bin/3proxy -C {CONFIG_FILE}"
#     stdout, stderr, code = run_command(cmd)
    
#     if code != 0:
#         logging.error(f"Config syntax check failed: {stderr}")
#         return False, stderr
    
#     logging.info(f"Config syntax check passed")
#     return True, "Config syntax is valid"

# Hàm tạo lại toàn bộ file cấu hình từ data.txt
def regenerate_config():
    try:
        # Đảm bảo thư mục tồn tại
        os.makedirs(os.path.dirname(CONFIG_FILE), exist_ok=True)
        
        # Tạo file cấu hình mới
        cmd = f"""
        cat > {CONFIG_FILE} << EOF
daemon
maxconn 3000
nserver 1.1.1.1
nserver 1.0.0.1
nserver 2001:4860:4860::8888
nserver 2001:4860:4860::8844
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
stacksize 6291456 
pidfile {PID_FILE}
flush
auth $(awk -F "|" '{{print $3}}' {SUBNET_FILE})
users $(awk -F "|" 'BEGIN{{ORS="";}} {{print $1 ":CL:" $2 " "}}' {DATA_FILE})
$(awk -F "|" '{{print "auth " $3"\\n" \\
"allow " $1 "\\n" \\
"proxy -6 -n -a -p" $6 " -i" $5 " -e"$7"\\n" \\
"flush\\n"}}' {DATA_FILE})
EOF
        """
        _, stderr, code = run_command(cmd)
        
        if code != 0:
            logging.error(f"Failed to regenerate config: {stderr}")
            return False, stderr
        
        # Kiểm tra cú pháp của file mới
        # valid, msg = check_config_syntax()
        # if not valid:
        #     logging.error(f"Regenerated config has syntax errors: {msg}")
        #     return False, msg
        
        return True, "Config regenerated successfully"
    except Exception as e:
        logging.error(f"Error regenerating config: {str(e)}")
        return False, str(e)

# Hàm cập nhật cấu hình cho một port cụ thể
def update_port_config(port, new_ipv6):
    try:
        # Sao lưu file cấu hình trước
        if not backup_config():
            return False, "Failed to backup config"
        
        # Đọc file cấu hình hiện tại
        with open(CONFIG_FILE, 'r') as f:
            config_lines = f.readlines()
        
        # Tìm và cập nhật dòng chứa port cụ thể
        updated = False
        for i, line in enumerate(config_lines):
            # Tìm dòng chứa port với các định dạng có thể có
            if (f" -p{port} " in line or f"-p{port} " in line or 
                f" -p{port}" in line or f" -p {port}" in line):
                
                # Tìm IPv6 trong dòng và thay thế
                parts = line.split(" ")
                for j, part in enumerate(parts):
                    if part.startswith("-e"):
                        old_part = parts[j]
                        parts[j] = f"-e{new_ipv6}\n"
                        updated = True
                        break
                
                if updated:
                    config_lines[i] = " ".join(parts)
                    break
        
        if not updated:
            logging.warning(f"Port {port} not found in config, regenerating entire config")
            success, msg = regenerate_config()
            if not success:
                restore_config()
                return False, f"Failed to regenerate config: {msg}"
            return True, "Config regenerated"
        
        # Ghi lại file cấu hình
        with open(CONFIG_FILE, 'w') as f:
            f.writelines(config_lines)
        
        # Kiểm tra cú pháp
        # valid, msg = check_config_syntax()
        # if not valid:
        #     logging.error(f"Updated config has syntax errors: {msg}")
        #     restore_config()
        #     return False, f"Config syntax error: {msg}"
        
        return True, "Config updated successfully"
    
    except Exception as e:
        logging.error(f"Error updating port config: {str(e)}")
        restore_config()
        return False, f"Error: {str(e)}"

# Hàm thêm IPv6 mới vào interface mạng
def add_ipv6_to_interface(interface, ipv6, prefix):
    try:
        # Thêm IPv6 mới
        add_cmd = f"ip -6 addr add {ipv6}/{prefix} dev {interface}"
        _, add_err, add_code = run_command(add_cmd)
        
        if add_code != 0:
            logging.error(f"Failed to add IPv6 to interface: {add_err}")
            return False, add_err
        
        logging.info(f"Added IPv6 {ipv6}/{prefix} to interface {interface}")
        return True, f"Added IPv6 {ipv6}/{prefix} to interface {interface}"
    
    except Exception as e:
        logging.error(f"Error adding IPv6 to interface: {str(e)}")
        return False, str(e)

# Hàm xóa IPv6 cũ khỏi interface mạng
def remove_ipv6_from_interface(interface, ipv6, prefix):
    try:
        # Xóa IPv6 cũ
        del_cmd = f"ip -6 addr del {ipv6}/{prefix} dev {interface} 2>/dev/null || true"
        _, del_err, del_code = run_command(del_cmd)
        
        # Không kiểm tra mã lỗi vì có thể IPv6 đã không còn tồn tại
        logging.info(f"Removed IPv6 {ipv6}/{prefix} from interface {interface}")
        return True, f"Removed IPv6 {ipv6}/{prefix} from interface {interface}"
    
    except Exception as e:
        logging.error(f"Error removing IPv6 from interface: {str(e)}")
        return False, str(e)

# Hàm lấy PID của 3proxy
def get_3proxy_pid():
    # Thử đọc từ file pid trước
    if os.path.exists(PID_FILE):
        try:
            with open(PID_FILE, 'r') as f:
                pid = f.read().strip()
                if pid and pid.isdigit():
                    # Kiểm tra xem process có tồn tại không
                    if os.path.exists(f"/proc/{pid}"):
                        return pid
        except Exception as e:
            logging.warning(f"Failed to read PID from file: {str(e)}")
    
    # Nếu không đọc được từ file, dùng pidof
    pid_cmd = "pidof 3proxy"
    pid_output, _, pid_code = run_command(pid_cmd)
    
    if pid_code == 0 and pid_output.strip():
        return pid_output.strip()
    
    # Thử các cách khác để tìm PID
    ps_cmd = "ps aux | grep 3proxy | grep -v grep | awk '{print $2}'"
    ps_output, _, ps_code = run_command(ps_cmd)
    
    if ps_code == 0 and ps_output.strip():
        return ps_output.strip().split("\n")[0]
    
    return None

# Hàm reload cấu hình 3proxy
def reload_3proxy_config():
    pid = get_3proxy_pid()
    
    if pid:
        # Sử dụng SIGUSR1 để reload cấu hình theo tài liệu 3proxy
        _, usr1_err, usr1_code = run_command(f"kill -USR1 {pid}")
        if usr1_code == 0:
            logging.info(f"Sent SIGUSR1 to 3proxy (PID: {pid}) to reload config")
            # Đợi một chút để 3proxy có thể reload
            time.sleep(1)
            return True, f"Reloaded 3proxy configuration (PID: {pid})"
        else:
            logging.warning(f"Failed to send SIGUSR1: {usr1_err}")
    
    logging.warning("Could not find 3proxy PID or reload failed, trying restart")
    
    # Nếu reload không thành công, thử khởi động lại
    #return restart_3proxy()

# Hàm khởi động lại 3proxy
def restart_3proxy():
    try:
        # Thử dùng systemctl trước
        _, restart_err, restart_code = run_command("systemctl restart 3proxy")
        
        if restart_code == 0:
            logging.info("Restarted 3proxy service via systemctl")
            time.sleep(2)  # Đợi để dịch vụ khởi động
            
            # Kiểm tra xem dịch vụ đã chạy chưa
            _, status_err, status_code = run_command("systemctl is-active 3proxy")
            if status_code == 0:
                return True, "Restarted 3proxy service successfully"
            else:
                logging.error(f"3proxy service failed to start: {status_err}")
        else:
            logging.warning(f"Failed to restart via systemctl: {restart_err}")
        
        # Nếu systemctl không thành công, thử khởi động thủ công
        logging.info("Trying to start 3proxy manually")
        
        # Kiểm tra xem 3proxy có đang chạy không và kill nếu cần
        pid = get_3proxy_pid()
        if pid:
            run_command(f"kill {pid}")
            time.sleep(1)
        
        # Khởi động 3proxy thủ công
        manual_cmd = "/usr/local/etc/3proxy/bin/3proxy /usr/local/etc/3proxy/3proxy.cfg"
        _, manual_err, manual_code = run_command(manual_cmd)
        
        if manual_code != 0:
            logging.error(f"Failed to manually start 3proxy: {manual_err}")
            return False, f"Failed to start 3proxy: {manual_err}"
        
        # Kiểm tra xem 3proxy đã chạy chưa
        time.sleep(2)
        pid = get_3proxy_pid()
        if pid:
            logging.info(f"Manually started 3proxy (PID: {pid})")
            return True, f"Manually started 3proxy (PID: {pid})"
        else:
            logging.error("3proxy failed to start manually")
            return False, "3proxy failed to start manually"
    
    except Exception as e:
        logging.error(f"Error restarting 3proxy: {str(e)}")
        return False, f"Error restarting 3proxy: {str(e)}"

# Hàm tạo IPv6 mới cho port cụ thể - phiên bản cải tiến
def generate_new_ipv6_for_port(port):
    try:
        # Đọc thông tin subnet từ file
        with open(SUBNET_FILE, 'r') as f:
            subnet_info = f.read().strip()
        
        subnet_parts = subnet_info.split('|')
        if len(subnet_parts) < 6:
            logging.error("Không thể đọc thông tin subnet")
            return False, "Không thể đọc thông tin subnet"
        
        IP6 = subnet_parts[0]
        Prefix = subnet_parts[1]
        interface = subnet_parts[4]
        
        # Đọc thông tin proxy hiện tại
        with open(DATA_FILE, 'r') as f:
            lines = f.readlines()
        
        # Tìm dòng chứa port cần thay đổi
        port_line = None
        port_index = None
        for i, line in enumerate(lines):
            if f"|{port}|" in line:
                port_line = line
                port_index = i
                break
        
        if port_line is None:
            logging.error(f"Không tìm thấy port {port} trong cấu hình")
            return False, f"Không tìm thấy port {port} trong cấu hình"
        
        # Tạo IPv6 mới
        new_ipv6 = gen_ipv6(IP6, Prefix)
        
        # Cập nhật dòng cấu hình với IPv6 mới
        parts = port_line.strip().split('|')
        old_ipv6 = parts[6]
        parts[6] = new_ipv6
        new_line = '|'.join(parts) + '\n'
        
        # Sao lưu data.txt trước khi cập nhật
        shutil.copy2(DATA_FILE, f"{DATA_FILE}.bak")
        
        # Cập nhật data.txt
        lines[port_index] = new_line
        with open(DATA_FILE, 'w') as f:
            f.writelines(lines)
        
        logging.info(f"Đã cập nhật IPv6 cho port {port} trong data.txt: {old_ipv6} -> {new_ipv6}")
        
        # Thêm IPv6 mới vào interface mạng trước khi cập nhật cấu hình
        add_success, add_msg = add_ipv6_to_interface(interface, new_ipv6, Prefix)
        if not add_success:
            return False, f"Không thể thêm IPv6 mới vào interface: {add_msg}"
        
        # Cập nhật cấu hình 3proxy
        update_success, update_msg = update_port_config(port, new_ipv6)
        if not update_success:
            # Nếu cập nhật cấu hình thất bại, xóa IPv6 mới đã thêm
            remove_ipv6_from_interface(interface, new_ipv6, Prefix)
            return False, f"Không thể cập nhật cấu hình: {update_msg}"
        
        # Reload cấu hình 3proxy
        reload_success, reload_msg = reload_3proxy_config()
        if not reload_success:
            # Nếu reload thất bại, khôi phục cấu hình và IPv6
            restore_config()
            remove_ipv6_from_interface(interface, new_ipv6, Prefix)
            return False, f"Không thể reload cấu hình 3proxy: {reload_msg}"
        
        # Chỉ xóa IPv6 cũ sau khi đã reload thành công
        time.sleep(1)  # Đợi một chút để đảm bảo 3proxy đã sử dụng IPv6 mới
        remove_ipv6_from_interface(interface, old_ipv6, Prefix)
        
        logging.info(f"Đã xoay thành công IPv6 cho port {port}")
        return True, {"old_ipv6": old_ipv6, "new_ipv6": new_ipv6, "port": port}
    
    except Exception as e:
        logging.error(f"Lỗi không xác định: {str(e)}")
        return False, f"Lỗi không xác định: {str(e)}"

@app.route('/rotate_ipv6', methods=['POST'])
@require_api_key
def rotate_ipv6():
    try:
        logging.debug(f"Received request: {request.data}")
        data = request.get_json()
        if not data:
            logging.warning("Request không có dữ liệu JSON")
            return jsonify({"success": False, "message": "Thiếu dữ liệu JSON"}), 400
        
        logging.debug(f"Request data: {data}")
        ip_port = data.get('ip_port')
        if not ip_port:
            logging.warning("Thiếu tham số ip_port trong request")
            return jsonify({"success": False, "message": "Thiếu tham số ip_port"}), 400
        
        # Phân tích ip:port
        try:
            ip, port = ip_port.split(':')
            port = port.strip()
            logging.debug(f"Parsed IP: {ip}, Port: {port}")
        except:
            logging.warning(f"Định dạng ip_port không hợp lệ: {ip_port}")
            return jsonify({"success": False, "message": "Định dạng không hợp lệ. Sử dụng ip:port"}), 400
        
        # Thực hiện xoay IPv6
        logging.info(f"Bắt đầu xoay IPv6 cho {ip_port}")
        success, result = generate_new_ipv6_for_port(port)
        
        if success:
            return jsonify({"success": True, "data": result})
        else:
            return jsonify({"success": False, "message": result}), 500
    
    except Exception as e:
        logging.error(f"Lỗi server: {str(e)}")
        return jsonify({"success": False, "message": f"Lỗi server: {str(e)}"}), 500

@app.route('/status', methods=['GET'])
def status():
    return jsonify({"status": "API đang hoạt động", "version": "1.0"})

# Thêm endpoint để test không cần authentication
@app.route('/test', methods=['GET'])
def test():
    return jsonify({"status": "API test endpoint is working", "time": time.time()})

if __name__ == '__main__':
    logging.info("Starting IPv6 Rotation API on port 8080")
    app.run(host='0.0.0.0', port=8080)
