import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

/// --- Simple models & state ---
enum OrderStatus { pending, confirmed, deleted }

class GasOrder {
  final String id;
  final String customerName;
  final String phone;
  final int cylinders;
  final double? lat;
  final double? lng;
  final DateTime createdAt;
  OrderStatus status;
  GasOrder({
    required this.id,
    required this.customerName,
    required this.phone,
    required this.cylinders,
    this.lat,
    this.lng,
    required this.createdAt,
    this.status = OrderStatus.pending,
  });
}

class AppState extends ChangeNotifier {
  bool agentEnabled = true;
  final List<GasOrder> _orders = [];

  // Hardcoded credentials
  final String agentEmail = 'agent@example.com';
  final String agentPassword = '123456';
  final String adminEmail = 'admin@example.com';
  final String adminPassword = 'admin123';

  List<GasOrder> get orders => List.unmodifiable(_orders);
  List<GasOrder> get activeOrders =>
      _orders.where((o) => o.status != OrderStatus.deleted).toList();

  int get totalCylindersSold => _orders
      .where((o) => o.status == OrderStatus.confirmed)
      .fold(0, (sum, o) => sum + o.cylinders);

  void addOrder({
    required String name,
    required String phone,
    required int qty,
    double? lat,
    double? lng,
  }) {
    _orders.insert(
      0,
      GasOrder(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        customerName: name,
        phone: phone,
        cylinders: qty,
        lat: lat,
        lng: lng,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void confirm(String id) {
    final o = _orders.firstWhere((e) => e.id == id);
    o.status = OrderStatus.confirmed;
    notifyListeners();
  }

  void softDelete(String id) {
    final o = _orders.firstWhere((e) => e.id == id);
    o.status = OrderStatus.deleted;
    notifyListeners();
  }

  void hardDelete(String id) {
    _orders.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void toggleAgent(bool v) {
    agentEnabled = v;
    notifyListeners();
  }
}

/// --- App & routing ---
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppState state = AppState();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gas Agent Minimal',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.green),
      home: InheritedAppState(
        state: state,
        child: const LoginPage(),
      ),
      routes: {
        '/order': (_) => InheritedAppState(state: state, child: const UserOrderPage()),
        '/agent': (_) => InheritedAppState(state: state, child: const AgentDashboard()),
        '/admin': (_) => InheritedAppState(state: state, child: const AdminDashboard()),
      },
    );
  }
}

/// Very small InheritedWidget to pass AppState down the tree.
class InheritedAppState extends InheritedNotifier<AppState> {
  final AppState state;
  const InheritedAppState({super.key, required this.state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedAppState>()!.state;
}

/// --- Pages ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailC = TextEditingController();
  final passC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('تطبيق معتمد الغاز (نسخة خفيفة)')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton.icon(
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('إضافة طلب غاز (بدون تسجيل)'),
                onPressed: () => Navigator.pushNamed(context, '/order'),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('تسجيل الدخول (للمعتمد/الإدارة):'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: emailC,
                textDirection: TextDirection.ltr,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passC,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  final email = emailC.text.trim();
                  final pass = passC.text;
                  if (email == state.agentEmail && pass == state.agentPassword) {
                    if (!state.agentEnabled) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('حساب المعتمد معطّل من قبل الإدارة')),
                      );
                      return;
                    }
                    Navigator.pushNamed(context, '/agent');
                  } else if (email == state.adminEmail && pass == state.adminPassword) {
                    Navigator.pushNamed(context, '/admin');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('بيانات الدخول غير صحيحة')),
                    );
                  }
                },
                child: const Text('تسجيل الدخول'),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: const [
                      Text('بيانات للتجربة:'),
                      SizedBox(height: 6),
                      SelectableText('المعتمد: agent@example.com / 123456'),
                      SelectableText('الإدارة:  admin@example.com / admin123'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserOrderPage extends StatefulWidget {
  const UserOrderPage({super.key});
  @override
  State<UserOrderPage> createState() => _UserOrderPageState();
}

class _UserOrderPageState extends State<UserOrderPage> {
  final nameC = TextEditingController();
  final phoneC = TextEditingController();
  final qtyC = TextEditingController(text: '1');
  final latC = TextEditingController();
  final lngC = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('طلب اسطوانات غاز')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                textDirection: TextDirection.rtl,
                controller: nameC,
                decoration: const InputDecoration(labelText: 'اسم الزبون', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                textDirection: TextDirection.ltr,
                controller: phoneC,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الهاتف', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: qtyC,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'عدد الاسطوانات', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              Container(
                height: 180,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.black12),
                ),
                child: const Text('خريطة (نسخة خفيفة بلا إنترنت) - أدخل الإحداثيات يدويًا أدناه'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latC,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lngC,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                      decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                icon: const Icon(Icons.send),
                label: const Text('إرسال الطلب'),
                onPressed: () {
                  final name = nameC.text.trim();
                  final phone = phoneC.text.trim();
                  final qty = int.tryParse(qtyC.text) ?? 1;
                  final lat = double.tryParse(latC.text);
                  final lng = double.tryParse(lngC.text);
                  if (name.isEmpty || phone.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أدخل الاسم والهاتف')));
                    return;
                  }
                  state.addOrder(name: name, phone: phone, qty: qty, lat: lat, lng: lng);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال الطلب')));
                  nameC.clear(); phoneC.clear(); qtyC.text = '1'; latC.clear(); lngC.clear();
                },
              ),
              const SizedBox(height: 12),
              const Text('رقم المعتمد للتواصل: +1234567890'),
            ],
          ),
        ),
      ),
    );
  }
}

class AgentDashboard extends StatelessWidget {
  const AgentDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة المعتمد')),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          final list = state.activeOrders;
          if (list.isEmpty) {
            return const Center(child: Text('لا توجد طلبات بعد'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: list.length,
            itemBuilder: (ctx, i) {
              final o = list[i];
              return Card(
                child: ListTile(
                  title: Text('${o.customerName} — ${o.cylinders} اسطوانة'),
                  subtitle: Text('هاتف: ${o.phone} • الحالة: ${o.status.name}${o.lat != null && o.lng != null ? " • (${o.lat!.toStringAsFixed(4)}, ${o.lng!.toStringAsFixed(4)})" : ""}'),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      if (o.status == OrderStatus.pending)
                        IconButton(
                          tooltip: 'تأكيد',
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () => state.confirm(o.id),
                        ),
                      IconButton(
                        tooltip: 'حذف',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => state.softDelete(o.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});
  @override
  Widget build(BuildContext context) {
    final state = InheritedAppState.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('لوحة الإدارة')),
      body: AnimatedBuilder(
        animation: state,
        builder: (context, _) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: ListTile(
                    title: const Text('إجمالي الاسطوانات المؤكدة'),
                    subtitle: Text('${state.totalCylindersSold} اسطوانة'),
                  ),
                ),
                SwitchListTile(
                  title: const Text('تفعيل حساب المعتمد'),
                  value: state.agentEnabled,
                  onChanged: (v) => state.toggleAgent(v),
                ),
                const SizedBox(height: 8),
                const Text('جميع الطلبات:'),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.orders.length,
                    itemBuilder: (ctx, i) {
                      final o = state.orders[i];
                      return Card(
                        child: ListTile(
                          title: Text('${o.customerName} — ${o.cylinders} اسطوانة'),
                          subtitle: Text('الحالة: ${o.status.name} — الهاتف: ${o.phone}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                            onPressed: () => state.hardDelete(o.id),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
