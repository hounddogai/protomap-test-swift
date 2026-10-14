import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy requests through their life cycle and keeps a journal of what it did.
    final class ProxyRequestDesk {
        var store: any ProxyRequestStore
        var validator: ProxyRequestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProxyRequestEngine

        init(store: any ProxyRequestStore, validator: ProxyRequestValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProxyRequestEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy request \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxyRequestStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy request \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxyRequestStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy request \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newProxyRequestDesk(_ store: any ProxyRequestStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ProxyRequestDesk {
        return ProxyRequestDesk(
            store: store,
            validator: defaultProxyRequestValidator(),
            clock: clock,
            journal: [],
            engine: defaultProxyRequestEngine(flags)
        )
    }
}
