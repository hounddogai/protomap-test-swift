import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves program records through their life cycle and keeps a journal of what it did.
    final class ProgramRecordService {
        var store: any ProgramRecordStore
        var validator: ProgramRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any ProgramRecordStore, validator: ProgramRecordValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProgramRecordStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProgramRecordStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
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

    static func newProgramRecordService(_ store: any ProgramRecordStore, clock: any Kit.Clocks.Clock) -> ProgramRecordService {
        return ProgramRecordService(
            store: store,
            validator: defaultProgramRecordValidator(),
            clock: clock,
            journal: []
        )
    }
}
