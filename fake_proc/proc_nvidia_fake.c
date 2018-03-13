#include <linux/module.h>
#include <linux/proc_fs.h>
#include <linux/seq_file.h>
#include <linux/kernel.h>
#include <linux/sched.h>
#include <asm/uaccess.h>
#include <linux/slab.h>
#include <linux/string.h>

static int len,temp;

static char *msg;
static char *dirname="driver/nvidia";
static char *dirname2="settings";
struct proc_dir_entry *subdirparent;
struct proc_dir_entry *parent;
struct proc_dir_entry *parent2;
static ssize_t read_proc(struct file *filp,char *buf,size_t count,loff_t *offp )
{
    if(count>temp){count=temp;}
    temp=temp-count;
    copy_to_user(buf,msg, count);
    if(count==0){temp=len;}

    return count;
}

static ssize_t write_proc(struct file *filp,const char *buf,size_t count,loff_t *offp)
{
    copy_from_user(msg,buf,count);
    len=count;
    temp=len;

    return count;
}

struct file_operations proc_fops = {
    read: read_proc,
    write: write_proc
};

static void create_new_proc_entry(void)
{
    parent = proc_mkdir(dirname, NULL);
    parent2 = proc_mkdir(dirname2,parent);
    proc_create("private_setting",0644,parent2,&proc_fops);
    msg=kmalloc(GFP_KERNEL,10*sizeof(char));
}


//static int proc_init (void)
static void proc_init (void)
{
 create_new_proc_entry();
 // return 0;
}

static void proc_cleanup(void)
{
    remove_proc_entry("private_setting",parent2);
    remove_proc_entry(dirname2,parent);
    remove_proc_entry(dirname,NULL);
}

static int hello_proc_show(struct seq_file *m, void *v) {
  seq_printf(m, "NVRM version: NVIDIA UNIX x86_64 Kernel Module  384.111  Tue Dec 19 23:51:45 PST 2017\n");
  return 0;
}

static int hello_proc_open(struct inode *inode, struct  file *file) {
  return single_open(file, hello_proc_show, NULL);
}

static const struct file_operations hello_proc_fops = {
  .owner = THIS_MODULE,
  .open = hello_proc_open,
  .read = seq_read,
  .llseek = seq_lseek,
  .release = single_release,
};

static int __init hello_proc_init(void) {
  proc_init ();
  proc_create("driver/nvidia/version", 0, NULL, &hello_proc_fops);
  
  return 0;
}

static void __exit hello_proc_exit(void) {
  remove_proc_entry("hello_proc", NULL);
  proc_cleanup();

}

MODULE_LICENSE("GPL");
module_init(hello_proc_init);
module_exit(hello_proc_exit);

