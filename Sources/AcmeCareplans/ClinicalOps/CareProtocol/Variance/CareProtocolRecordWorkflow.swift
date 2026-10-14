import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves care protocol records through their life cycle and keeps a journal of what it did.
    final class CareProtocolRecordWorkflow {
        var store: any CareProtocolRecordStore
        var validator: CareProtocolRecordValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareProtocolRecordEngine

        init(store: any CareProtocolRecordStore, validator: CareProtocolRecordValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareProtocolRecordEngine) {
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
                throw Kit.Failure("care protocol record \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolRecordStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol record \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolRecordStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol record \(code) not found")
            }
            let result = engine.evaluate(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.endsAt > cutoff {
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

    static func newCareProtocolRecordWorkflow(_ store: any CareProtocolRecordStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> CareProtocolRecordWorkflow {
        return CareProtocolRecordWorkflow(
            store: store,
            validator: defaultCareProtocolRecordValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareProtocolRecordEngine(flags)
        )
    }
}
