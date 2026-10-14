import AcmePlatform
import Foundation

extension Labs {
    /// Moves default courier milestones through their life cycle and keeps a journal of what it did.
    final class DefaultCourierMilestoneManager {
        var store: any DefaultCourierMilestoneStore
        var validator: DefaultCourierMilestoneValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DefaultCourierMilestoneEngine

        init(store: any DefaultCourierMilestoneStore, validator: DefaultCourierMilestoneValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DefaultCourierMilestoneEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default courier milestone \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DefaultCourierMilestoneStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("default courier milestone \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DefaultCourierMilestoneStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("default courier milestone \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newDefaultCourierMilestoneManager(_ store: any DefaultCourierMilestoneStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> DefaultCourierMilestoneManager {
        return DefaultCourierMilestoneManager(
            store: store,
            validator: defaultDefaultCourierMilestoneValidator(),
            clock: clock,
            journal: [],
            engine: defaultDefaultCourierMilestoneEngine(flags)
        )
    }
}
