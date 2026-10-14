import AcmePlatform
import Foundation

extension Imaging {
    /// Moves priority policies through their life cycle and keeps a journal of what it did.
    final class PriorityPolicyService {
        var store: any PriorityPolicyStore
        var validator: PriorityPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PriorityPolicyStore, validator: PriorityPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("priority policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PriorityPolicyStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("priority policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PriorityPolicyStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newPriorityPolicyService(_ store: any PriorityPolicyStore, clock: any Kit.Clocks.Clock) -> PriorityPolicyService {
        return PriorityPolicyService(
            store: store,
            validator: defaultPriorityPolicyValidator(),
            clock: clock,
            journal: []
        )
    }
}
