/*
 * w32xreadonlymemvfs - a spatialite vfs for accessing an in-memory read-only database with extensions for win32.
 *
 * By Alex Paterson, copyright 2012. http://www.tolon.co.uk
 * Uses readonlymemvfs, which is based on spmemvfs by Stephen Liu, copyright 2009. http://code.google.com/p/sphivedb/
 *
 * This code and its use is governed by the GNU GPLv2 licence as published by the Free Software Foundation.
 *
 */

/*
 * USAGE EXAMPLE:
 * 
 *  sqlite3* s_database;
 *
 *  void open_mem_db(void* pMemDb, size_t nSize)
 *	{
 *		char errcode = 0;
 *
 *		set_mem_db(pBuffer, dwSize);
 *
 *		int nInitResult = readonlymemvfs_init();
 *		assert(nInitResult == SQLITE_OK);
 *      if (nInitResult == SQLITE_OK)
 *			errcode = sqlite3_open_v2( "0", &s_database, SQLITE_OPEN_READONLY, READONLY_MEM_VFS_NAME );
 *
 *      // check errcode here
 *
 *		// database is now open and ready for use
 *	}
 *
 */

#pragma once

#define W32XREADONLY_MEM_VFS_NAME "w32xreadonly-mem-vfs"

int w32xreadonlymemvfs_init();

void set_mem_db( void* pData, unsigned int len );
