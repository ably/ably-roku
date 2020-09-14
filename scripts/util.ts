import * as fsExtra from 'fs-extra';
import * as path from 'path';

class Util {
	public scriptTitle: string;
	public logging: boolean = false;

	/**
	 * Determine if a file exists
	 * @param filePath
	 */
	public async fileExists(filePath: string) {
		return new Promise((resolve) => {
			fsExtra.exists(filePath, resolve);
		});
	}

	/**
	 * Reads and converts a json file to an object from the project
	 * @param {String} relativePath
	 * @returns {Object} object version of the file
	 */
	public async readJsonFile(relativePath: string): Promise<any> {
		const contents = await fsExtra.readFile(this.convertToAbsolutePath(relativePath), 'utf8');
		return JSON.parse(contents);
	}

	/**
	 * Helper to convert relative project paths to absolute paths
	 * @param {String} relativePath
	 * @returns {String} absolute path
	 */
	public convertToAbsolutePath(relativePath: string, basePath?: string): string {
		if (!basePath) {
			basePath = process.cwd();
		}
		return path.resolve(`${basePath}/${relativePath}`);
	}

	/**
	 * Creates a delay in execution
	 * @param ms time to delay in milliseconds
	 */
	public async delay(ms: number) {
		return new Promise((resolve) => setTimeout(resolve, ms));
	}

	public exit(error: Error) {
		console.log(`${this.scriptTitle} encountered error: `, error);
		process.exit(1);
	}

	public getEnvSetting(settingName, defaultValue) {
		return (settingName in process.env) ? process.env[settingName] === 'true' : defaultValue;
	}

	/**
	 * With return the differences in two objects
	 * @param obj1 base target
	 * @param obj2 comparison target
	 * @param exclude fields to exclude in the comparison
	 */
	public objectDiff(obj1: object, obj2: object, exclude?: string[]) {
		let r = {};

		if (!exclude) { exclude = []; }

		for (let prop in obj1) {
			if (obj1.hasOwnProperty(prop) && prop !== '__proto__') {
				if (exclude.indexOf(obj1[prop]) === -1) {

					// check if obj2 has prop
					if (!obj2.hasOwnProperty(prop)) { r[prop] = obj1[prop]; } else if (obj1[prop] === Object(obj1[prop])) {
						let difference = this.objectDiff(obj1[prop], obj2[prop]);
						if (Object.keys(difference).length > 0) { r[prop] = difference; }
					} else if (obj1[prop] !== obj2[prop]) {
						if (obj1[prop] === undefined) {
							r[prop] = 'undefined';
						}

						if (obj1[prop] === null) {
							r[prop] = null;
						} else if (typeof obj1[prop] === 'function') {
							r[prop] = 'function';
						} else if (typeof obj1[prop] === 'object') {
							r[prop] = 'object';
						} else {
							r[prop] = obj1[prop];
						}
					}
				}
			}
		}
		return r;
	}

	public dynamicSort(property) {
		let sortOrder = 1;
		if (property[0] === '-') {
				sortOrder = -1;
				property = property.substr(1);
		}
		return function (a, b) {
				/* next line works with strings and numbers,
				* and you may want to customize it to your needs
				*/
				let result = (a[property] < b[property]) ? -1 : (a[property] > b[property]) ? 1 : 0;
				return result * sortOrder;
		};
	}

	public isInArray(array: any[], field: string, value: any): boolean {
		return array.find((obj) => obj[field] === value) ? true : false;
	}

	public findWithAttr(array: any[], attr: string, value: any) {
		for (let i = 0; i < array.length; i += 1) {
				if (array[i][attr] === value) {
						return i;
				}
		}
		return -1;
	}

	public log(...args) {
		if (this.logging) console.log(...args);
	}

	public time(label: string) {
		if (this.logging) console.time(label);
	}

	public timeEnd(label: string) {
		if (this.logging) console.timeEnd(label);
	}
}

const util = new Util();
export {
	util
};
