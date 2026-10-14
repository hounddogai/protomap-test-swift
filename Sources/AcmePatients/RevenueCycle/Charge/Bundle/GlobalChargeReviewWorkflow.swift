import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves global charge reviews through their life cycle and keeps a journal of what it did.
    final class GlobalChargeReviewWorkflow {
        var store: any GlobalChargeReviewStore
        var validator: GlobalChargeReviewValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalChargeReviewStore, validator: GlobalChargeReviewValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global charge review \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalChargeReviewStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global charge review \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalChargeReviewStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newGlobalChargeReviewWorkflow(_ store: any GlobalChargeReviewStore, clock: any Kit.Clocks.Clock) -> GlobalChargeReviewWorkflow {
        return GlobalChargeReviewWorkflow(
            store: store,
            validator: defaultGlobalChargeReviewValidator(),
            clock: clock,
            journal: []
        )
    }
}
