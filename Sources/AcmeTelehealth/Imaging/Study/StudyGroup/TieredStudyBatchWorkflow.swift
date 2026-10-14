import AcmePlatform
import Foundation

extension Imaging {
    /// Moves tiered study batches through their life cycle and keeps a journal of what it did.
    final class TieredStudyBatchDesk {
        var store: any TieredStudyBatchStore
        var validator: TieredStudyBatchValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: TieredStudyBatchEngine

        init(store: any TieredStudyBatchStore, validator: TieredStudyBatchValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: TieredStudyBatchEngine) {
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
                throw Kit.Failure("tiered study batch \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredStudyBatchStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered study batch \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredStudyBatchStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered study batch \(code) not found")
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
                if item.updatedAt > cutoff {
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

    static func newTieredStudyBatchDesk(_ store: any TieredStudyBatchStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> TieredStudyBatchDesk {
        return TieredStudyBatchDesk(
            store: store,
            validator: defaultTieredStudyBatchValidator(),
            clock: clock,
            journal: [],
            engine: defaultTieredStudyBatchEngine(flags)
        )
    }
}
