import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves global goal records through their life cycle and keeps a journal of what it did.
    final class GlobalGoalRecordManager {
        var store: any GlobalGoalRecordStore
        var validator: GlobalGoalRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalGoalRecordEngine

        init(store: any GlobalGoalRecordStore, validator: GlobalGoalRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalGoalRecordEngine) {
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
                throw Kit.Failure("global goal record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalGoalRecordStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global goal record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalGoalRecordStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global goal record \(code) not found")
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

    static func newGlobalGoalRecordManager(_ store: any GlobalGoalRecordStore, clock: any Kit.Clocks.Clock) -> GlobalGoalRecordManager {
        return GlobalGoalRecordManager(
            store: store,
            validator: defaultGlobalGoalRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalGoalRecordEngine()
        )
    }
}
