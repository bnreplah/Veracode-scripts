/**
 * OnPrem JavaScript Library
 * A comprehensive JavaScript library for on-premises applications
 * Includes AJAX functionality, DOM manipulation, utilities, and more
 * No external dependencies required
 * 
 * @version 1.0.0
 * @author Custom Development
 */

(function(global) {
    'use strict';

    // Main library object
    const OnPrem = {};

    // Version
    OnPrem.version = '1.0.0';

    // ===========================================
    // AJAX FUNCTIONALITY
    // ===========================================
    
    OnPrem.ajax = function(options) {
        // Default options
        const defaults = {
            url: '',
            method: 'GET',
            data: null,
            headers: {},
            timeout: 30000,
            async: true,
            contentType: 'application/x-www-form-urlencoded; charset=UTF-8',
            dataType: 'json',
            beforeSend: null,
            success: null,
            error: null,
            complete: null
        };

        // Merge options with defaults
        const config = Object.assign({}, defaults, options);

        return new Promise((resolve, reject) => {
            const xhr = new XMLHttpRequest();
            
            // Set timeout
            xhr.timeout = config.timeout;
            
            // Open request
            xhr.open(config.method.toUpperCase(), config.url, config.async);
            
            // Set content type
            if (config.method.toUpperCase() !== 'GET') {
                xhr.setRequestHeader('Content-Type', config.contentType);
            }
            
            // Set custom headers
            for (const header in config.headers) {
                xhr.setRequestHeader(header, config.headers[header]);
            }
            
            // Before send callback
            if (typeof config.beforeSend === 'function') {
                config.beforeSend(xhr);
            }
            
            // Handle response
            xhr.onreadystatechange = function() {
                if (xhr.readyState === 4) {
                    let response = xhr.responseText;
                    
                    // Parse response based on dataType
                    try {
                        if (config.dataType === 'json' && response) {
                            response = JSON.parse(response);
                        }
                    } catch (e) {
                        console.warn('Failed to parse JSON response:', e);
                    }
                    
                    if (xhr.status >= 200 && xhr.status < 300) {
                        if (typeof config.success === 'function') {
                            config.success(response, xhr.status, xhr);
                        }
                        resolve(response);
                    } else {
                        if (typeof config.error === 'function') {
                            config.error(xhr, xhr.status, xhr.statusText);
                        }
                        reject(new Error(`HTTP ${xhr.status}: ${xhr.statusText}`));
                    }
                    
                    // Complete callback
                    if (typeof config.complete === 'function') {
                        config.complete(xhr, xhr.status);
                    }
                }
            };
            
            // Handle timeout
            xhr.ontimeout = function() {
                if (typeof config.error === 'function') {
                    config.error(xhr, 0, 'timeout');
                }
                reject(new Error('Request timeout'));
            };
            
            // Handle network errors
            xhr.onerror = function() {
                if (typeof config.error === 'function') {
                    config.error(xhr, 0, 'error');
                }
                reject(new Error('Network error'));
            };
            
            // Prepare data
            let sendData = null;
            if (config.data) {
                if (config.method.toUpperCase() === 'GET') {
                    // Append to URL for GET requests
                    const params = typeof config.data === 'string' ? config.data : OnPrem.param(config.data);
                    config.url += (config.url.includes('?') ? '&' : '?') + params;
                } else {
                    sendData = typeof config.data === 'string' ? config.data : 
                              config.contentType.includes('json') ? JSON.stringify(config.data) : 
                              OnPrem.param(config.data);
                }
            }
            
            // Send request
            xhr.send(sendData);
        });
    };

    // GET request shorthand
    OnPrem.get = function(url, data, success, dataType) {
        return OnPrem.ajax({
            url: url,
            method: 'GET',
            data: data,
            success: success,
            dataType: dataType || 'json'
        });
    };

    // POST request shorthand
    OnPrem.post = function(url, data, success, dataType) {
        return OnPrem.ajax({
            url: url,
            method: 'POST',
            data: data,
            success: success,
            dataType: dataType || 'json'
        });
    };

    // PUT request shorthand
    OnPrem.put = function(url, data, success, dataType) {
        return OnPrem.ajax({
            url: url,
            method: 'PUT',
            data: data,
            success: success,
            dataType: dataType || 'json'
        });
    };

    // DELETE request shorthand
    OnPrem.delete = function(url, success, dataType) {
        return OnPrem.ajax({
            url: url,
            method: 'DELETE',
            success: success,
            dataType: dataType || 'json'
        });
    };

    // ===========================================
    // DOM MANIPULATION
    // ===========================================

    OnPrem.$ = function(selector) {
        if (typeof selector === 'string') {
            return new OnPrem.DOMCollection(document.querySelectorAll(selector));
        } else if (selector instanceof Element) {
            return new OnPrem.DOMCollection([selector]);
        } else if (selector instanceof NodeList) {
            return new OnPrem.DOMCollection(selector);
        }
        return new OnPrem.DOMCollection([]);
    };

    // DOM Collection class
    OnPrem.DOMCollection = function(elements) {
        this.elements = Array.from(elements);
        this.length = this.elements.length;
        
        // Make it array-like
        for (let i = 0; i < this.length; i++) {
            this[i] = this.elements[i];
        }
    };

    OnPrem.DOMCollection.prototype = {
        // Each method
        each: function(callback) {
            this.elements.forEach(callback);
            return this;
        },

        // Text content
        text: function(value) {
            if (value === undefined) {
                return this.elements[0] ? this.elements[0].textContent : '';
            }
            return this.each(el => el.textContent = value);
        },

        // HTML content
        html: function(value) {
            if (value === undefined) {
                return this.elements[0] ? this.elements[0].innerHTML : '';
            }
            return this.each(el => el.innerHTML = value);
        },

        // Attribute manipulation
        attr: function(name, value) {
            if (value === undefined) {
                return this.elements[0] ? this.elements[0].getAttribute(name) : null;
            }
            return this.each(el => el.setAttribute(name, value));
        },

        removeAttr: function(name) {
            return this.each(el => el.removeAttribute(name));
        },

        // CSS manipulation
        css: function(property, value) {
            if (typeof property === 'object') {
                return this.each(el => {
                    for (const prop in property) {
                        el.style[prop] = property[prop];
                    }
                });
            }
            if (value === undefined) {
                return this.elements[0] ? getComputedStyle(this.elements[0])[property] : '';
            }
            return this.each(el => el.style[property] = value);
        },

        // Class manipulation
        addClass: function(className) {
            return this.each(el => el.classList.add(className));
        },

        removeClass: function(className) {
            return this.each(el => el.classList.remove(className));
        },

        toggleClass: function(className) {
            return this.each(el => el.classList.toggle(className));
        },

        hasClass: function(className) {
            return this.elements[0] ? this.elements[0].classList.contains(className) : false;
        },

        // Event handling
        on: function(event, handler) {
            return this.each(el => el.addEventListener(event, handler));
        },

        off: function(event, handler) {
            return this.each(el => el.removeEventListener(event, handler));
        },

        click: function(handler) {
            if (handler) {
                return this.on('click', handler);
            }
            return this.each(el => el.click());
        },

        // Show/Hide
        show: function() {
            return this.each(el => el.style.display = '');
        },

        hide: function() {
            return this.each(el => el.style.display = 'none');
        },

        toggle: function() {
            return this.each(el => {
                const display = getComputedStyle(el).display;
                el.style.display = display === 'none' ? '' : 'none';
            });
        },

        // Value for form elements
        val: function(value) {
            if (value === undefined) {
                return this.elements[0] ? this.elements[0].value : '';
            }
            return this.each(el => el.value = value);
        },

        // Append/Prepend
        append: function(content) {
            return this.each(el => {
                if (typeof content === 'string') {
                    el.insertAdjacentHTML('beforeend', content);
                } else {
                    el.appendChild(content);
                }
            });
        },

        prepend: function(content) {
            return this.each(el => {
                if (typeof content === 'string') {
                    el.insertAdjacentHTML('afterbegin', content);
                } else {
                    el.insertBefore(content, el.firstChild);
                }
            });
        },

        // Remove
        remove: function() {
            return this.each(el => el.remove());
        }
    };

    // ===========================================
    // UTILITY FUNCTIONS
    // ===========================================

    // Serialize object to URL parameters
    OnPrem.param = function(obj) {
        const params = [];
        for (const key in obj) {
            if (obj.hasOwnProperty(key)) {
                params.push(encodeURIComponent(key) + '=' + encodeURIComponent(obj[key]));
            }
        }
        return params.join('&');
    };

    // Deep merge objects
    OnPrem.extend = function(target, ...sources) {
        if (!sources.length) return target;
        const source = sources.shift();

        if (OnPrem.isObject(target) && OnPrem.isObject(source)) {
            for (const key in source) {
                if (OnPrem.isObject(source[key])) {
                    if (!target[key]) Object.assign(target, { [key]: {} });
                    OnPrem.extend(target[key], source[key]);
                } else {
                    Object.assign(target, { [key]: source[key] });
                }
            }
        }

        return OnPrem.extend(target, ...sources);
    };

    // Type checking utilities
    OnPrem.isObject = function(item) {
        return item && typeof item === 'object' && !Array.isArray(item);
    };

    OnPrem.isArray = function(item) {
        return Array.isArray(item);
    };

    OnPrem.isFunction = function(item) {
        return typeof item === 'function';
    };

    OnPrem.isString = function(item) {
        return typeof item === 'string';
    };

    OnPrem.isNumber = function(item) {
        return typeof item === 'number' && !isNaN(item);
    };

    // Array utilities
    OnPrem.each = function(array, callback) {
        if (Array.isArray(array)) {
            array.forEach(callback);
        } else {
            for (const key in array) {
                if (array.hasOwnProperty(key)) {
                    callback(array[key], key);
                }
            }
        }
    };

    OnPrem.map = function(array, callback) {
        return Array.from(array).map(callback);
    };

    OnPrem.filter = function(array, callback) {
        return Array.from(array).filter(callback);
    };

    // ===========================================
    // FORM UTILITIES
    // ===========================================

    OnPrem.serializeForm = function(form) {
        const formData = new FormData(form);
        const data = {};
        for (const [key, value] of formData.entries()) {
            if (data[key]) {
                if (Array.isArray(data[key])) {
                    data[key].push(value);
                } else {
                    data[key] = [data[key], value];
                }
            } else {
                data[key] = value;
            }
        }
        return data;
    };

    OnPrem.serializeFormToString = function(form) {
        return OnPrem.param(OnPrem.serializeForm(form));
    };

    // ===========================================
    // STORAGE UTILITIES
    // ===========================================

    OnPrem.storage = {
        set: function(key, value) {
            try {
                localStorage.setItem(key, JSON.stringify(value));
                return true;
            } catch (e) {
                console.error('Storage set error:', e);
                return false;
            }
        },

        get: function(key) {
            try {
                const item = localStorage.getItem(key);
                return item ? JSON.parse(item) : null;
            } catch (e) {
                console.error('Storage get error:', e);
                return null;
            }
        },

        remove: function(key) {
            try {
                localStorage.removeItem(key);
                return true;
            } catch (e) {
                console.error('Storage remove error:', e);
                return false;
            }
        },

        clear: function() {
            try {
                localStorage.clear();
                return true;
            } catch (e) {
                console.error('Storage clear error:', e);
                return false;
            }
        }
    };

    // ===========================================
    // COOKIE UTILITIES
    // ===========================================

    OnPrem.cookies = {
        set: function(name, value, days) {
            let expires = '';
            if (days) {
                const date = new Date();
                date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
                expires = '; expires=' + date.toUTCString();
            }
            document.cookie = name + '=' + encodeURIComponent(value) + expires + '; path=/';
        },

        get: function(name) {
            const nameEQ = name + '=';
            const cookies = document.cookie.split(';');
            for (let cookie of cookies) {
                cookie = cookie.trim();
                if (cookie.indexOf(nameEQ) === 0) {
                    return decodeURIComponent(cookie.substring(nameEQ.length));
                }
            }
            return null;
        },

        remove: function(name) {
            document.cookie = name + '=; expires=Thu, 01 Jan 1970 00:00:01 GMT; path=/';
        }
    };

    // ===========================================
    // VALIDATION UTILITIES
    // ===========================================

    OnPrem.validate = {
        email: function(email) {
            const pattern = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            return pattern.test(email);
        },

        phone: function(phone) {
            const pattern = /^[\+]?[1-9][\d]{0,15}$/;
            return pattern.test(phone.replace(/\s/g, ''));
        },

        url: function(url) {
            try {
                new URL(url);
                return true;
            } catch {
                return false;
            }
        },

        required: function(value) {
            return value !== null && value !== undefined && value !== '';
        },

        minLength: function(value, length) {
            return value && value.length >= length;
        },

        maxLength: function(value, length) {
            return value && value.length <= length;
        }
    };

    // ===========================================
    // ANIMATION UTILITIES
    // ===========================================

    OnPrem.animate = function(element, properties, duration, callback) {
        duration = duration || 300;
        const start = performance.now();
        const startValues = {};
        
        // Get initial values
        for (const prop in properties) {
            const currentValue = parseFloat(getComputedStyle(element)[prop]) || 0;
            startValues[prop] = currentValue;
        }

        function animate(currentTime) {
            const elapsed = currentTime - start;
            const progress = Math.min(elapsed / duration, 1);
            
            // Easing function (ease-in-out)
            const easeInOut = progress < 0.5 ? 
                2 * progress * progress : 
                -1 + (4 - 2 * progress) * progress;

            for (const prop in properties) {
                const startValue = startValues[prop];
                const endValue = parseFloat(properties[prop]);
                const currentValue = startValue + (endValue - startValue) * easeInOut;
                element.style[prop] = currentValue + (prop.includes('opacity') ? '' : 'px');
            }

            if (progress < 1) {
                requestAnimationFrame(animate);
            } else if (callback) {
                callback();
            }
        }

        requestAnimationFrame(animate);
    };

    // ===========================================
    // READY FUNCTION
    // ===========================================

    OnPrem.ready = function(callback) {
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', callback);
        } else {
            callback();
        }
    };

    // ===========================================
    // EXPORT
    // ===========================================

    // Export to global scope
    global.OnPrem = OnPrem;
    global.$ = OnPrem.$; // jQuery-like syntax

    // Support for module systems
    if (typeof module !== 'undefined' && module.exports) {
        module.exports = OnPrem;
    } else if (typeof define === 'function' && define.amd) {
        define(function() { return OnPrem; });
    }

})(typeof window !== 'undefined' ? window : this);

// ===========================================
// USAGE EXAMPLES
// ===========================================

/*
// AJAX Examples:
OnPrem.ajax({
    url: '/api/data',
    method: 'GET',
    success: function(data) {
        console.log('Success:', data);
    },
    error: function(xhr, status, error) {
        console.error('Error:', error);
    }
});

OnPrem.get('/api/users', function(users) {
    console.log('Users:', users);
});

OnPrem.post('/api/users', {name: 'John', email: 'john@example.com'})
    .then(response => console.log('User created:', response))
    .catch(error => console.error('Error:', error));

// DOM Manipulation:
OnPrem.$('#myElement').text('Hello World');
OnPrem.$('.my-class').addClass('active').show();
OnPrem.$('button').on('click', function() {
    alert('Button clicked!');
});

// Form handling:
const formData = OnPrem.serializeForm(document.getElementById('myForm'));
console.log('Form data:', formData);

// Storage:
OnPrem.storage.set('user', {name: 'John', role: 'admin'});
const user = OnPrem.storage.get('user');

// Cookies:
OnPrem.cookies.set('session', 'abc123', 7);
const session = OnPrem.cookies.get('session');

// Validation:
if (OnPrem.validate.email('test@example.com')) {
    console.log('Valid email');
}

// Animation:
OnPrem.animate(document.getElementById('box'), {
    left: '100px',
    opacity: '0.5'
}, 500, function() {
    console.log('Animation complete');
});

// Ready function:
OnPrem.ready(function() {
    console.log('DOM is ready');
});
*/