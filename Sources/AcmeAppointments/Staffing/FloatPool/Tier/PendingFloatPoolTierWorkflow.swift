import AcmePlatform
import Foundation

extension Staffing {
    /// Moves pending float pool tiers through their life cycle and keeps a journal of what it did.
    final class PendingFloatPoolTierService {
        var store: any PendingFloatPoolTierStore
        var validator: PendingFloatPoolTierValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any PendingFloatPoolTierStore, validator: PendingFloatPoolTierValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("pending float pool tier \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingFloatPoolTierStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending float pool tier \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingFloatPoolTierStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newPendingFloatPoolTierService(_ store: any PendingFloatPoolTierStore, clock: any Kit.Clocks.Clock) -> PendingFloatPoolTierService {
        return PendingFloatPoolTierService(
            store: store,
            validator: defaultPendingFloatPoolTierValidator(),
            clock: clock,
            journal: []
        )
    }
}
