import AcmePlatform
import Foundation

extension Consent {
    /// Moves proxy digests through their life cycle and keeps a journal of what it did.
    final class ProxyDigestWorkflow {
        var store: any ProxyDigestStore
        var validator: ProxyDigestValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ProxyDigestStore, validator: ProxyDigestValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("proxy digest \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProxyDigestStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("proxy digest \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProxyDigestStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newProxyDigestWorkflow(_ store: any ProxyDigestStore, clock: any Kit.Clocks.Clock) -> ProxyDigestWorkflow {
        return ProxyDigestWorkflow(store: store, validator: defaultProxyDigestValidator(), clock: clock, journal: [])
    }
}
