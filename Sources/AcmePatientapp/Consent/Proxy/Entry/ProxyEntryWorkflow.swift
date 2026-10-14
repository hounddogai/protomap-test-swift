import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy entries through their life cycle and keeps a journal of what it did.
    final class ProxyEntryWorkflow {
        var store: any ProxyEntryStore
        var validator: ProxyEntryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProxyEntryEngine

        init(store: any ProxyEntryStore, validator: ProxyEntryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProxyEntryEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy entry \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxyEntryStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy entry \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxyEntryStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy entry \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.createdAt > cutoff {
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

    static func newProxyEntryWorkflow(_ store: any ProxyEntryStore, clock: any Kit.Clocks.Clock) -> ProxyEntryWorkflow {
        return ProxyEntryWorkflow(
            store: store,
            validator: defaultProxyEntryValidator(),
            clock: clock,
            journal: [],
            engine: defaultProxyEntryEngine()
        )
    }
}
