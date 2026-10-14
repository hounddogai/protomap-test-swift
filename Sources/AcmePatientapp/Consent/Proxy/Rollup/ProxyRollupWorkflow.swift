import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy rollups through their life cycle and keeps a journal of what it did.
    final class ProxyRollupManager {
        var store: any ProxyRollupStore
        var validator: ProxyRollupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProxyRollupEngine

        init(store: any ProxyRollupStore, validator: ProxyRollupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProxyRollupEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy rollup \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxyRollupStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy rollup \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxyRollupStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy rollup \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                let problems = validator.validate(item)
                if problems.count == 0 {
                    continue
                }
                self.note("\(item.code) needs attention: \(problems.joined(separator: ", "))")
                changed += 1
            }
            return changed
        }
    }

    static func newProxyRollupManager(_ store: any ProxyRollupStore, clock: any Kit.Clocks.Clock) -> ProxyRollupManager {
        return ProxyRollupManager(
            store: store,
            validator: defaultProxyRollupValidator(),
            clock: clock,
            journal: [],
            engine: defaultProxyRollupEngine()
        )
    }
}
