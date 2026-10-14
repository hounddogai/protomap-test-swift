import AcmePlatform
import Foundation

extension Pharmacy {
    /// Moves global dispense summaries through their life cycle and keeps a journal of what it did.
    final class GlobalDispenseSummaryService {
        var store: any GlobalDispenseSummaryStore
        var validator: GlobalDispenseSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any GlobalDispenseSummaryStore, validator: GlobalDispenseSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global dispense summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalDispenseSummaryStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global dispense summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalDispenseSummaryStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
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

    static func newGlobalDispenseSummaryService(_ store: any GlobalDispenseSummaryStore, clock: any Kit.Clocks.Clock) -> GlobalDispenseSummaryService {
        return GlobalDispenseSummaryService(
            store: store,
            validator: defaultGlobalDispenseSummaryValidator(),
            clock: clock,
            journal: []
        )
    }
}
