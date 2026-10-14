import AcmePlatform
import Foundation

extension Imaging {
    /// Moves priority variances through their life cycle and keeps a journal of what it did.
    final class PriorityVarianceService {
        var store: any PriorityVarianceStore
        var validator: PriorityVarianceValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PriorityVarianceStore, validator: PriorityVarianceValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("priority variance \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PriorityVarianceStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("priority variance \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PriorityVarianceStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newPriorityVarianceService(_ store: any PriorityVarianceStore, clock: any Kit.Clocks.Clock) -> PriorityVarianceService {
        return PriorityVarianceService(
            store: store,
            validator: defaultPriorityVarianceValidator(),
            clock: clock,
            journal: []
        )
    }
}
