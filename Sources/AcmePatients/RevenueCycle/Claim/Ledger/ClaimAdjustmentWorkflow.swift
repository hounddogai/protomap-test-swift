import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves claim adjustments through their life cycle and keeps a journal of what it did.
    final class ClaimAdjustmentService {
        var store: any ClaimAdjustmentStore
        var validator: ClaimAdjustmentValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ClaimAdjustmentStore, validator: ClaimAdjustmentValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim adjustment \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ClaimAdjustmentStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("claim adjustment \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ClaimAdjustmentStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newClaimAdjustmentService(_ store: any ClaimAdjustmentStore, clock: any Kit.Clocks.Clock) -> ClaimAdjustmentService {
        return ClaimAdjustmentService(
            store: store,
            validator: defaultClaimAdjustmentValidator(),
            clock: clock,
            journal: []
        )
    }
}
