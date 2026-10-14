import AcmePlatform
import Foundation

extension Staffing {
    /// Moves skill mix allocations through their life cycle and keeps a journal of what it did.
    final class SkillMixAllocationCoordinator {
        var store: any SkillMixAllocationStore
        var validator: SkillMixAllocationValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SkillMixAllocationStore, validator: SkillMixAllocationValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("skill mix allocation \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SkillMixAllocationStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix allocation \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SkillMixAllocationStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func audit(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newSkillMixAllocationCoordinator(_ store: any SkillMixAllocationStore, clock: any Kit.Clocks.Clock) -> SkillMixAllocationCoordinator {
        return SkillMixAllocationCoordinator(
            store: store,
            validator: defaultSkillMixAllocationValidator(),
            clock: clock,
            journal: []
        )
    }
}
