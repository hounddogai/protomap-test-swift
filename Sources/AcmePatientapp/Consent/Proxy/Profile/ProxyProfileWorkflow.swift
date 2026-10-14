import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy profiles through their life cycle and keeps a journal of what it did.
    final class ProxyProfileWorkflow {
        var store: any ProxyProfileStore
        var validator: ProxyProfileValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ProxyProfileStore, validator: ProxyProfileValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy profile \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxyProfileStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy profile \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxyProfileStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
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

    static func newProxyProfileWorkflow(_ store: any ProxyProfileStore, clock: any Kit.Clocks.Clock) -> ProxyProfileWorkflow {
        return ProxyProfileWorkflow(
            store: store,
            validator: defaultProxyProfileValidator(),
            clock: clock,
            journal: []
        )
    }
}
