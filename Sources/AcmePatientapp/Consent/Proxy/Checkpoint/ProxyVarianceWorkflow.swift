import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy variances through their life cycle and keeps a journal of what it did.
    final class ProxyVarianceDesk {
        var store: any ProxyVarianceStore
        var validator: ProxyVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ProxyVarianceStore, validator: ProxyVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("proxy variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxyVarianceStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxyVarianceStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newProxyVarianceDesk(_ store: any ProxyVarianceStore, clock: any Kit.Clocks.Clock) -> ProxyVarianceDesk {
        return ProxyVarianceDesk(store: store, validator: defaultProxyVarianceValidator(), clock: clock, journal: [])
    }
}
