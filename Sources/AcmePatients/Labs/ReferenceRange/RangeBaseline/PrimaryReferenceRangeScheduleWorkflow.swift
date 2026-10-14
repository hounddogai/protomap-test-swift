import AcmePlatform
import Foundation

extension Labs {
    /// Moves primary reference range schedules through their life cycle and keeps a journal of what it did.
    final class PrimaryReferenceRangeScheduleManager {
        var store: any PrimaryReferenceRangeScheduleStore
        var validator: PrimaryReferenceRangeScheduleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PrimaryReferenceRangeScheduleEngine

        init(store: any PrimaryReferenceRangeScheduleStore, validator: PrimaryReferenceRangeScheduleValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PrimaryReferenceRangeScheduleEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary reference range schedule \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PrimaryReferenceRangeScheduleStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary reference range schedule \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PrimaryReferenceRangeScheduleStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func evaluate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("primary reference range schedule \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newPrimaryReferenceRangeScheduleManager(_ store: any PrimaryReferenceRangeScheduleStore, clock: any Kit.Clocks.Clock) -> PrimaryReferenceRangeScheduleManager {
        return PrimaryReferenceRangeScheduleManager(
            store: store,
            validator: defaultPrimaryReferenceRangeScheduleValidator(),
            clock: clock,
            journal: [],
            engine: defaultPrimaryReferenceRangeScheduleEngine()
        )
    }
}
