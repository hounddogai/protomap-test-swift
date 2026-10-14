import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves lenient program groups through their life cycle and keeps a journal of what it did.
    final class LenientProgramGroupWorkflow {
        var store: any LenientProgramGroupStore
        var validator: LenientProgramGroupValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: LenientProgramGroupEngine

        init(store: any LenientProgramGroupStore, validator: LenientProgramGroupValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: LenientProgramGroupEngine) {
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
                throw Kit.Failure("lenient program group \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientProgramGroupStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient program group \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientProgramGroupStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient program group \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
            var changed = 0
            for item in store.list() {
                if item.isTerminal() {
                    continue
                }
                if item.startsAt > cutoff {
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

    static func newLenientProgramGroupWorkflow(_ store: any LenientProgramGroupStore, clock: any Kit.Clocks.Clock) -> LenientProgramGroupWorkflow {
        return LenientProgramGroupWorkflow(
            store: store,
            validator: defaultLenientProgramGroupValidator(),
            clock: clock,
            journal: [],
            engine: defaultLenientProgramGroupEngine()
        )
    }
}
