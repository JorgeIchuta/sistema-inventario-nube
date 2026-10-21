const navItems = [
  { id: 'panel', label: 'Panel', icon: '▦' },
  { id: 'productos', label: 'Productos', icon: '▣' },
  { id: 'categorias', label: 'Categorías', icon: '◈' },
  { id: 'proveedores', label: 'Proveedores', icon: '▱' },
  { id: 'entradas', label: 'Entradas', icon: '⇥' },
  { id: 'ventas', label: 'Ventas', icon: '🛒' },
  { id: 'stock', label: 'Bajo stock', icon: '⚠' },
  { id: 'historial', label: 'Historial', icon: '↶' },
  { id: 'usuarios', label: 'Usuarios', icon: '♙' }
];

const products = [
  { id: 1, code: 'SKU-9921', name: 'Laptop Pro X15', category: 'Electrónica', price: 1299, stock: 45, min: 10, icon: '💻' },
  { id: 2, code: 'SKU-4832', name: 'Silla Ergonómica Serie 3', category: 'Mobiliario', price: 249.50, stock: 8, min: 15, icon: '🪑' },
  { id: 3, code: 'SKU-1044', name: 'Monitor UltraWide 34 pulgadas', category: 'Electrónica', price: 699, stock: 0, min: 5, icon: '🖥️' },
  { id: 4, code: 'SKU-7751', name: 'Cajas de Archivo (Pack 10)', category: 'Oficina', price: 34, stock: 120, min: 20, icon: '📦' },
  { id: 5, code: 'SKU-2210', name: 'Teclado Mecánico Inalámbrico', category: 'Electrónica', price: 120, stock: 3, min: 8, icon: '⌨️' },
  { id: 6, code: 'SKU-8802', name: 'Cuaderno Ejecutivo', category: 'Oficina', price: 12.90, stock: 67, min: 15, icon: '📓' }
];

const categories = [
  { name: 'Electrónica', description: 'Equipos y periféricos', products: 3, active: true },
  { name: 'Mobiliario', description: 'Muebles para oficina', products: 1, active: true },
  { name: 'Oficina', description: 'Papelería y organización', products: 2, active: true }
];

const suppliers = [
  { name: 'Tecnología del Centro', phone: '555 010 2211', email: 'ventas@teccentro.test', status: 'Activo' },
  { name: 'Muebles Nova', phone: '555 010 3480', email: 'contacto@mueblesnova.test', status: 'Activo' },
  { name: 'Papelería Universal', phone: '555 010 9901', email: 'pedidos@papeleria.test', status: 'Activo' }
];

const movements = [
  { product: 'Laptop Pro X15', type: 'Venta', date: 'Hoy, 10:24', user: 'Ana López', qty: -2 },
  { product: 'Ratón Inalámbrico MX', type: 'Entrada', date: 'Hoy, 09:45', user: 'Carlos Ruiz', qty: 50 },
  { product: 'Silla Ergonómica Serie 3', type: 'Ajuste', date: 'Ayer, 16:20', user: 'Admin Usuario', qty: -1 },
  { product: 'Cajas de Archivo', type: 'Entrada', date: 'Ayer, 12:10', user: 'Admin Usuario', qty: 30 }
];

let currentView = 'panel';
let saleCart = [
  { productId: 2, quantity: 2 },
  { productId: 5, quantity: 1 }
];

const app = document.querySelector('#app');
const desktopNav = document.querySelector('#desktop-nav');
const mobileNav = document.querySelector('#mobile-nav');
const sidebar = document.querySelector('#sidebar');
const scrim = document.querySelector('#scrim');
const modal = document.querySelector('#modal');
const modalForm = document.querySelector('#modal-form');

function money(value) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(value);
}

function statusFor(product) {
  if (product.stock === 0) return { label: 'Agotado', kind: 'danger' };
  if (product.stock <= product.min) return { label: 'Stock bajo', kind: 'warning' };
  return { label: 'En stock', kind: 'success' };
}

function navButton(item) {
  return `<button class="nav-item ${currentView === item.id ? 'active' : ''}" data-view="${item.id}"><span class="nav-icon">${item.icon}</span><span>${item.label}</span></button>`;
}

function renderNav() {
  desktopNav.innerHTML = navItems.map(navButton).join('');
  mobileNav.innerHTML = navItems.filter(item => ['panel', 'productos', 'ventas'].includes(item.id)).map(navButton).join('');
}

function pageHeader(title, description, action = '') {
  return `<div class="page-header"><div><h1>${title}</h1><p>${description}</p></div><div class="page-actions">${action}</div></div>`;
}

function renderPanel() {
  const lowStock = products.filter(p => p.stock <= p.min);
  return `<section class="page">
    ${pageHeader('Resumen general', 'Vista rápida del inventario al día de hoy.', `
      <button class="button secondary" data-view="entradas">＋ <span class="label">Registrar entrada</span></button>
      <button class="button primary" data-view="ventas">🛒 <span class="label">Registrar venta</span></button>`)}
    <div class="stats">
      <article class="stat-card"><div class="stat-top"><span class="stat-icon">▣</span><span class="trend">↗ +2.4%</span></div><p>Total de productos</p><strong>${products.length}</strong></article>
      <article class="stat-card"><div class="stat-top"><span class="stat-icon success">$</span><span class="trend">↗ +12%</span></div><p>Ventas del día</p><strong>${money(3450)}</strong></article>
      <article class="stat-card"><div class="stat-top"><span class="stat-icon">⇥</span><span class="trend">Hoy</span></div><p>Entradas recientes</p><strong>3</strong></article>
      <article class="stat-card"><div class="stat-top"><span class="stat-icon warning">⚠</span><span class="badge danger">Atención</span></div><p>Bajo stock</p><strong>${lowStock.length}</strong></article>
    </div>
    <div class="dashboard-grid">
      <article class="card"><div class="card-heading"><h2>Ventas semanales</h2><button class="text-button">Ver detalle</button></div><div class="chart">
        ${[48,72,62,86,93,77,41].map((n,i) => `<div class="bar-wrap"><div class="bar ${i === 4 ? 'highlight' : ''}" style="--value:${n}%"></div><span>${['Lun','Mar','Mié','Jue','Vie','Sáb','Dom'][i]}</span></div>`).join('')}
      </div></article>
      <article class="card"><div class="card-heading"><h2>Alertas de stock</h2><button class="text-button" data-view="stock">Ver todo</button></div><div class="alert-list">
        ${lowStock.slice(0,3).map(productRow).join('')}
      </div></article>
      <article class="card activity-card"><div class="card-heading"><h2>Movimientos recientes</h2><button class="text-button" data-view="historial">Ver historial</button></div><div class="activity-list">
        ${movements.slice(0,3).map(m => `<div class="activity-row"><span class="product-thumb">${m.type === 'Venta' ? '🛒' : m.type === 'Entrada' ? '📥' : '↔'}</span><div class="row-copy"><strong>${m.product}</strong><small>${m.date} · ${m.user}</small></div><span class="badge ${m.type === 'Entrada' ? 'success' : m.type === 'Venta' ? 'warning' : 'danger'}">${m.type} ${m.qty > 0 ? '+' : ''}${m.qty}</span></div>`).join('')}
      </div></article>
    </div>
  </section>`;
}

function productRow(p) {
  const status = statusFor(p);
  return `<div class="alert-row"><span class="product-thumb">${p.icon}</span><div class="row-copy"><strong>${p.name}</strong><small>${p.code}</small></div><span class="badge ${status.kind}">${p.stock} uds.</span></div>`;
}

function renderProducts() {
  return `<section class="page">
    ${pageHeader('Productos', 'Gestiona el catálogo y controla los niveles de inventario.', '<button class="button primary" data-modal="producto">＋ <span class="label">Agregar producto</span></button>')}
    <div class="toolbar"><label class="field-inline"><input id="product-search" type="search" placeholder="Buscar por código o nombre..."></label><label class="field-inline"><select id="category-filter"><option value="">Todas las categorías</option>${categories.map(c => `<option>${c.name}</option>`).join('')}</select></label><label class="field-inline"><select id="status-filter"><option value="">Todos los estados</option><option>En stock</option><option>Stock bajo</option><option>Agotado</option></select></label></div>
    <div class="card table-shell"><table><thead><tr><th>Código</th><th>Producto</th><th>Categoría</th><th class="numeric">Precio</th><th class="numeric">Stock</th><th class="numeric">Mín.</th><th>Estado</th><th>Acciones</th></tr></thead><tbody id="product-table-body"></tbody></table><div class="product-cards" id="product-cards"></div><div class="empty" id="product-empty" hidden>No se encontraron productos.</div></div>
  </section>`;
}

function fillProducts() {
  const query = (document.querySelector('#product-search')?.value || '').toLowerCase();
  const category = document.querySelector('#category-filter')?.value || '';
  const status = document.querySelector('#status-filter')?.value || '';
  const filtered = products.filter(p => (!query || `${p.code} ${p.name}`.toLowerCase().includes(query)) && (!category || p.category === category) && (!status || statusFor(p).label.toLowerCase() === status.toLowerCase()));
  const tbody = document.querySelector('#product-table-body');
  const cards = document.querySelector('#product-cards');
  const empty = document.querySelector('#product-empty');
  if (!tbody) return;
  tbody.innerHTML = filtered.map(p => { const s = statusFor(p); return `<tr><td class="money">${p.code}</td><td><div class="product-name"><span class="product-thumb">${p.icon}</span>${p.name}</div></td><td>${p.category}</td><td class="numeric">${money(p.price)}</td><td class="numeric">${p.stock}</td><td class="numeric">${p.min}</td><td><span class="badge ${s.kind}">${s.label}</span></td><td><div class="table-actions"><button class="icon-button" title="Ver producto">⌕</button><button class="icon-button" title="Editar producto" data-modal="producto">✎</button></div></td></tr>`; }).join('');
  cards.innerHTML = filtered.map(p => { const s = statusFor(p); return `<article class="product-mobile-card"><div class="product-mobile-top"><span class="product-thumb">${p.icon}</span><div class="row-copy"><small>${p.code}</small><h3>${p.name}</h3><span>${p.category}</span></div><span class="badge ${s.kind}">${s.label}</span></div><div class="product-mobile-meta"><strong class="money">${money(p.price)}</strong><span>Existencias: <strong>${p.stock}</strong></span></div></article>`; }).join('');
  empty.hidden = filtered.length > 0;
}

function genericTable(title, description, columns, rows, modalType) {
  return `<section class="page">${pageHeader(title, description, modalType ? `<button class="button primary" data-modal="${modalType}">＋ <span class="label">Agregar</span></button>` : '')}<div class="card table-shell"><table><thead><tr>${columns.map(c => `<th>${c}</th>`).join('')}</tr></thead><tbody>${rows}</tbody></table></div></section>`;
}

function renderCategories() {
  return genericTable('Categorías', 'Organiza los productos del inventario.', ['Nombre','Descripción','Productos','Estado','Acciones'], categories.map(c => `<tr><td><strong>${c.name}</strong></td><td>${c.description}</td><td>${c.products}</td><td><span class="badge success">Activa</span></td><td><button class="icon-button" data-modal="categoria" title="Editar">✎</button></td></tr>`).join(''), 'categoria');
}

function renderSuppliers() {
  return genericTable('Proveedores', 'Administra los datos de contacto de tus proveedores.', ['Nombre','Teléfono','Correo','Estado','Acciones'], suppliers.map(s => `<tr><td><strong>${s.name}</strong></td><td>${s.phone}</td><td>${s.email}</td><td><span class="badge success">${s.status}</span></td><td><button class="icon-button" data-modal="proveedor" title="Editar">✎</button></td></tr>`).join(''), 'proveedor');
}

function renderEntries() {
  const rows = [
    ['ENT-0018','Tecnología del Centro','Hoy, 09:45','$4,890.00','Carlos Ruiz'],
    ['ENT-0017','Papelería Universal','Ayer, 12:10','$1,020.00','Admin Usuario'],
    ['ENT-0016','Muebles Nova','28 ago., 16:30','$3,745.00','Admin Usuario']
  ].map(r => `<tr>${r.map((v,i) => `<td class="${i === 3 ? 'money' : ''}">${v}</td>`).join('')}<td><span class="badge success">Confirmada</span></td></tr>`).join('');
  return genericTable('Entradas de mercancía', 'Consulta y registra el abastecimiento de productos.', ['Folio','Proveedor','Fecha','Total','Usuario','Estado'], rows, 'entrada');
}

function renderSales() {
  const subtotal = saleCart.reduce((sum, item) => sum + products.find(p => p.id === item.productId).price * item.quantity, 0);
  return `<section class="page">${pageHeader('Registrar venta', 'Selecciona productos y confirma la operación.')}
    <div class="sale-layout"><article class="card"><div class="toolbar"><label class="field-inline"><input id="sale-search" type="search" placeholder="Buscar producto o SKU..."></label><button class="button secondary" id="scan-button">▥ Escanear</button></div><div class="sale-items">
      ${saleCart.map(item => { const p = products.find(product => product.id === item.productId); const s = statusFor(p); return `<div class="sale-item"><span class="product-thumb">${p.icon}</span><div class="row-copy"><strong>${p.name}</strong><small>${p.code}</small><span class="badge ${s.kind}">${s.label}: ${p.stock}</span></div><span class="money">${money(p.price * item.quantity)}</span><div class="quantity"><button data-qty="-1" data-id="${p.id}" aria-label="Reducir cantidad">−</button><strong>${item.quantity}</strong><button data-qty="1" data-id="${p.id}" aria-label="Aumentar cantidad">+</button></div></div>`; }).join('')}
    </div></article><aside class="card totals"><h2>Resumen de venta</h2><div class="total-line"><span>Productos</span><span>${saleCart.reduce((s,i) => s + i.quantity, 0)}</span></div><div class="total-line"><span>Subtotal</span><span>${money(subtotal)}</span></div><div class="total-line"><span>Impuestos</span><span>Incluidos</span></div><div class="total-line final"><span>Total</span><span>${money(subtotal)}</span></div><button class="button primary" id="confirm-sale">✓ Confirmar venta</button></aside></div>
  </section>`;
}

function renderLowStock() {
  const low = products.filter(p => p.stock <= p.min);
  const rows = low.map(p => { const s = statusFor(p); return `<tr><td><div class="product-name"><span class="product-thumb">${p.icon}</span>${p.name}</div></td><td>${p.code}</td><td class="numeric">${p.stock}</td><td class="numeric">${p.min}</td><td><span class="badge ${s.kind}">${s.label}</span></td><td><button class="button secondary" data-modal="entrada">Registrar entrada</button></td></tr>`; }).join('');
  return genericTable('Bajo stock', 'Productos que necesitan reposición.', ['Producto','Código','Existencias','Mínimo','Estado','Acción'], rows);
}

function renderHistory() {
  const rows = movements.map(m => `<tr><td>${m.date}</td><td><strong>${m.product}</strong></td><td><span class="badge ${m.type === 'Entrada' ? 'success' : m.type === 'Venta' ? 'warning' : 'danger'}">${m.type}</span></td><td class="numeric">${m.qty > 0 ? '+' : ''}${m.qty}</td><td>${m.user}</td></tr>`).join('');
  return genericTable('Historial de movimientos', 'Auditoría de entradas, ventas y ajustes.', ['Fecha','Producto','Tipo','Cantidad','Usuario'], rows);
}

function renderUsers() {
  const rows = [
    ['Admin Usuario','admin@inventario.test','Administrador'],
    ['Ana López','ana@inventario.test','Empleado'],
    ['Carlos Ruiz','carlos@inventario.test','Empleado']
  ].map(u => `<tr><td><strong>${u[0]}</strong></td><td>${u[1]}</td><td>${u[2]}</td><td><span class="badge success">Activo</span></td><td><button class="icon-button" data-modal="usuario" title="Editar">✎</button></td></tr>`).join('');
  return genericTable('Usuarios', 'Controla las cuentas y permisos del sistema.', ['Nombre','Correo','Rol','Estado','Acciones'], rows, 'usuario');
}

const renderers = { panel: renderPanel, productos: renderProducts, categorias: renderCategories, proveedores: renderSuppliers, entradas: renderEntries, ventas: renderSales, stock: renderLowStock, historial: renderHistory, usuarios: renderUsers };

function render() {
  renderNav();
  app.innerHTML = renderers[currentView]();
  if (currentView === 'productos') fillProducts();
  app.focus({ preventScroll: true });
}

function navigate(view) {
  if (!renderers[view]) return;
  currentView = view;
  sidebar.classList.remove('open');
  scrim.classList.remove('show');
  render();
}

const modalConfigs = {
  producto: { title: 'Producto', fields: [['Código','text'],['Nombre','text'],['Categoría','select'],['Precio de venta','number'],['Stock mínimo','number'],['Descripción','textarea']] },
  categoria: { title: 'Categoría', fields: [['Nombre','text'],['Descripción','textarea']] },
  proveedor: { title: 'Proveedor', fields: [['Nombre','text'],['Teléfono','tel'],['Correo','email'],['Dirección','textarea']] },
  entrada: { title: 'Entrada de mercancía', fields: [['Proveedor','select'],['Producto','select'],['Cantidad','number'],['Costo unitario','number'],['Observaciones','textarea']] },
  usuario: { title: 'Usuario', fields: [['Nombre','text'],['Correo','email'],['Rol','select']] }
};

function openModal(type) {
  const config = modalConfigs[type];
  if (!config) return;
  document.querySelector('#modal-title').textContent = config.title;
  document.querySelector('#modal-content').innerHTML = config.fields.map(([label,type], index) => {
    const full = type === 'textarea' ? 'full' : '';
    let control = `<input type="${type}" ${type === 'number' ? 'min="0" step="0.01"' : ''} required>`;
    if (type === 'textarea') control = '<textarea></textarea>';
    if (type === 'select') control = `<select required><option value="">Seleccionar...</option><option>Opción de demostración</option></select>`;
    return `<div class="form-field ${full}"><label for="modal-field-${index}">${label}</label>${control.replace('>', ` id="modal-field-${index}">`)}</div>`;
  }).join('');
  modal.showModal();
}

function showToast(message) {
  const toast = document.querySelector('#toast');
  toast.textContent = message;
  toast.classList.add('show');
  clearTimeout(showToast.timer);
  showToast.timer = setTimeout(() => toast.classList.remove('show'), 2600);
}

document.addEventListener('click', event => {
  const viewButton = event.target.closest('[data-view]');
  if (viewButton) navigate(viewButton.dataset.view);
  const modalButton = event.target.closest('[data-modal]');
  if (modalButton) openModal(modalButton.dataset.modal);
  const qtyButton = event.target.closest('[data-qty]');
  if (qtyButton) {
    const item = saleCart.find(i => i.productId === Number(qtyButton.dataset.id));
    const product = products.find(p => p.id === item.productId);
    item.quantity = Math.max(1, Math.min(product.stock, item.quantity + Number(qtyButton.dataset.qty)));
    render();
  }
  if (event.target.closest('#confirm-sale')) showToast('Venta simulada correctamente. No se modificaron datos reales.');
  if (event.target.closest('#scan-button')) showToast('Simulación: cámara lista para escanear un código.');
});

document.addEventListener('input', event => {
  if (['product-search','category-filter','status-filter'].includes(event.target.id)) fillProducts();
  if (event.target.id === 'global-search' && event.target.value.trim()) {
    if (currentView !== 'productos') navigate('productos');
    const search = document.querySelector('#product-search');
    if (search) { search.value = event.target.value; fillProducts(); }
  }
});

document.querySelector('#menu-button').addEventListener('click', () => { sidebar.classList.add('open'); scrim.classList.add('show'); });
scrim.addEventListener('click', () => { sidebar.classList.remove('open'); scrim.classList.remove('show'); });
modalForm.addEventListener('submit', event => { if (event.submitter?.value === 'default') showToast('Datos guardados en el prototipo visual.'); });

render();
