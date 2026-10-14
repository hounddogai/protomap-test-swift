import AcmePlatform
import Foundation

extension Staffing {
    /// Moves global float pool summaries through their life cycle and keeps a journal of what it did.
    final class GlobalFloatPoolSummaryService {
        var store: any GlobalFloatPoolSummaryStore
        var validator: GlobalFloatPoolSummaryValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalFloatPoolSummaryEngine

        init(store: any GlobalFloatPoolSummaryStore, validator: GlobalFloatPoolSummaryValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalFloatPoolSummaryEngine) {
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
                throw Kit.Failure("global float pool summary \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalFloatPoolSummaryStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global float pool summary \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalFloatPoolSummaryStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global float pool summary \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newGlobalFloatPoolSummaryService(_ store: any GlobalFloatPoolSummaryStore, clock: any Kit.Clocks.Clock) -> GlobalFloatPoolSummaryService {
        return GlobalFloatPoolSummaryService(
            store: store,
            validator: defaultGlobalFloatPoolSummaryValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalFloatPoolSummaryEngine()
        )
    }
}
