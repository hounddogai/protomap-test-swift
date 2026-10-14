import AcmePlatform
import Foundation

extension Staffing {
    /// Moves skill mix cycles through their life cycle and keeps a journal of what it did.
    final class SkillMixCycleDesk {
        var store: any SkillMixCycleStore
        var validator: SkillMixCycleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SkillMixCycleStore, validator: SkillMixCycleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("skill mix cycle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SkillMixCycleStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix cycle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SkillMixCycleStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newSkillMixCycleDesk(_ store: any SkillMixCycleStore, clock: any Kit.Clocks.Clock) -> SkillMixCycleDesk {
        return SkillMixCycleDesk(store: store, validator: defaultSkillMixCycleValidator(), clock: clock, journal: [])
    }
}
