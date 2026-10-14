import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves rolling task records through their life cycle and keeps a journal of what it did.
    final class RollingTaskRecordWorkflow {
        var store: any RollingTaskRecordStore
        var validator: RollingTaskRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any RollingTaskRecordStore, validator: RollingTaskRecordValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("rolling task record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingTaskRecordStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling task record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingTaskRecordStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newRollingTaskRecordWorkflow(_ store: any RollingTaskRecordStore, clock: any Kit.Clocks.Clock) -> RollingTaskRecordWorkflow {
        return RollingTaskRecordWorkflow(
            store: store,
            validator: defaultRollingTaskRecordValidator(),
            clock: clock,
            journal: []
        )
    }
}
