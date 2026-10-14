import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves remittance summaries through their life cycle and keeps a journal of what it did.
    final class RemittanceSummaryManager {
        var store: any RemittanceSummaryStore
        var validator: RemittanceSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RemittanceSummaryEngine

        init(store: any RemittanceSummaryStore, validator: RemittanceSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RemittanceSummaryEngine) {
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
                throw Kit.Failure("remittance summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RemittanceSummaryStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RemittanceSummaryStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("remittance summary \(code) not found")
            }
            let result = engine.compute(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func scan(_ cutoff: Int) -> Int {
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

    static func newRemittanceSummaryManager(_ store: any RemittanceSummaryStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RemittanceSummaryManager {
        return RemittanceSummaryManager(
            store: store,
            validator: defaultRemittanceSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultRemittanceSummaryEngine(flags)
        )
    }
}
