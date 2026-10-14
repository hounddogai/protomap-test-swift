import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves scheduled bed board targets through their life cycle and keeps a journal of what it did.
    final class ScheduledBedBoardTargetManager {
        var store: any ScheduledBedBoardTargetStore
        var validator: ScheduledBedBoardTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledBedBoardTargetEngine

        init(store: any ScheduledBedBoardTargetStore, validator: ScheduledBedBoardTargetValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledBedBoardTargetEngine) {
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
                throw Kit.Failure("scheduled bed board target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledBedBoardTargetStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled bed board target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledBedBoardTargetStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled bed board target \(code) not found")
            }
            let result = engine.run(item)
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

    static func newScheduledBedBoardTargetManager(_ store: any ScheduledBedBoardTargetStore, clock: any Kit.Clocks.Clock) -> ScheduledBedBoardTargetManager {
        return ScheduledBedBoardTargetManager(
            store: store,
            validator: defaultScheduledBedBoardTargetValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledBedBoardTargetEngine()
        )
    }
}
