import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rounding allocations through their life cycle and keeps a journal of what it did.
    final class RoundingAllocationService {
        var store: any RoundingAllocationStore
        var validator: RoundingAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RoundingAllocationStore, validator: RoundingAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rounding allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RoundingAllocationStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rounding allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RoundingAllocationStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func scan(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.expiresAt > cutoff {
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

    static func newRoundingAllocationService(_ store: any RoundingAllocationStore, clock: any Kit.Clocks.Clock) -> RoundingAllocationService {
        return RoundingAllocationService(
            store: store,
            validator: defaultRoundingAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
