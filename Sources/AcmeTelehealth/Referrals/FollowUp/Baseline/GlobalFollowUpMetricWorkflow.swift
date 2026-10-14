import AcmePlatform
import Foundation

extension Referrals {
    /// Moves global follow up metrics through their life cycle and keeps a journal of what it did.
    final class GlobalFollowUpMetricDesk {
        var store: any GlobalFollowUpMetricStore
        var validator: GlobalFollowUpMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: GlobalFollowUpMetricEngine

        init(store: any GlobalFollowUpMetricStore, validator: GlobalFollowUpMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: GlobalFollowUpMetricEngine) {
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
                throw Kit.Failure("global follow up metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(GlobalFollowUpMetricStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("global follow up metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(GlobalFollowUpMetricStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("global follow up metric \(code) not found")
            }
            let result = engine.run(item)
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

    static func newGlobalFollowUpMetricDesk(_ store: any GlobalFollowUpMetricStore, clock: any Kit.Clocks.Clock) -> GlobalFollowUpMetricDesk {
        return GlobalFollowUpMetricDesk(
            store: store,
            validator: defaultGlobalFollowUpMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultGlobalFollowUpMetricEngine()
        )
    }
}
