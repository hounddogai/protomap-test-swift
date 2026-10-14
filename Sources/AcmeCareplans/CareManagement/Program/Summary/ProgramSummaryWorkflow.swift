import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves program summaries through their life cycle and keeps a journal of what it did.
    final class ProgramSummaryDesk {
        var store: any ProgramSummaryStore
        var validator: ProgramSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ProgramSummaryEngine

        init(store: any ProgramSummaryStore, validator: ProgramSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ProgramSummaryEngine) {
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
                throw Kit.Failure("program summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ProgramSummaryStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("program summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ProgramSummaryStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("program summary \(code) not found")
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
                if item.createdAt > cutoff {
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

    static func newProgramSummaryDesk(_ store: any ProgramSummaryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ProgramSummaryDesk {
        return ProgramSummaryDesk(
            store: store,
            validator: defaultProgramSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultProgramSummaryEngine(flags)
        )
    }
}
