import AcmePlatform
import Foundation

extension Imaging {
    /// Moves study summaries through their life cycle and keeps a journal of what it did.
    final class StudySummaryCoordinator {
        var store: any StudySummaryStore
        var validator: StudySummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: StudySummaryEngine

        init(store: any StudySummaryStore, validator: StudySummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: StudySummaryEngine) {
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
                throw Kit.Failure("study summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(StudySummaryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("study summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(StudySummaryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("study summary \(code) not found")
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

    static func newStudySummaryCoordinator(_ store: any StudySummaryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> StudySummaryCoordinator {
        return StudySummaryCoordinator(
            store: store,
            validator: defaultStudySummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultStudySummaryEngine(flags)
        )
    }
}
