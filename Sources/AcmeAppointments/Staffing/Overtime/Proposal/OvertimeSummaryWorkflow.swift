import AcmePlatform
import Foundation

extension Staffing {
    /// Moves overtime summaries through their life cycle and keeps a journal of what it did.
    final class OvertimeSummaryDesk {
        var store: any OvertimeSummaryStore
        var validator: OvertimeSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OvertimeSummaryEngine

        init(store: any OvertimeSummaryStore, validator: OvertimeSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OvertimeSummaryEngine) {
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
                throw Kit.Failure("overtime summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OvertimeSummaryStatus.queued)
            store.save(item)
            self.note("\(code) is queued")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OvertimeSummaryStatus.failed)
            store.save(item)
            self.note("\(code) is failed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime summary \(code) not found")
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

    static func newOvertimeSummaryDesk(_ store: any OvertimeSummaryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> OvertimeSummaryDesk {
        return OvertimeSummaryDesk(
            store: store,
            validator: defaultOvertimeSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultOvertimeSummaryEngine(flags)
        )
    }
}
