import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves dispense records through their life cycle and keeps a journal of what it did.
    final class DispenseRecordService {
        var store: any DispenseRecordStore
        var validator: DispenseRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: DispenseRecordEngine

        init(store: any DispenseRecordStore, validator: DispenseRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: DispenseRecordEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func submit(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(DispenseRecordStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(DispenseRecordStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("dispense record \(code) not found")
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

    static func newDispenseRecordService(_ store: any DispenseRecordStore, clock: any Kit.Clocks.Clock) -> DispenseRecordService {
        return DispenseRecordService(
            store: store,
            validator: defaultDispenseRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultDispenseRecordEngine()
        )
    }
}
