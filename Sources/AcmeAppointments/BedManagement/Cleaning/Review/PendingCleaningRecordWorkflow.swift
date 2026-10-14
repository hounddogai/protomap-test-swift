import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves pending cleaning records through their life cycle and keeps a journal of what it did.
    final class PendingCleaningRecordDesk {
        var store: any PendingCleaningRecordStore
        var validator: PendingCleaningRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingCleaningRecordEngine

        init(store: any PendingCleaningRecordStore, validator: PendingCleaningRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingCleaningRecordEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending cleaning record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingCleaningRecordStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending cleaning record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingCleaningRecordStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending cleaning record \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
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

    static func newPendingCleaningRecordDesk(_ store: any PendingCleaningRecordStore, clock: any Kit.Clocks.Clock) -> PendingCleaningRecordDesk {
        return PendingCleaningRecordDesk(
            store: store,
            validator: defaultPendingCleaningRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingCleaningRecordEngine()
        )
    }
}
