import AcmePlatform
import Foundation

extension Staffing {
    /// Moves pending overtime metrics through their life cycle and keeps a journal of what it did.
    final class PendingOvertimeMetricDesk {
        var store: any PendingOvertimeMetricStore
        var validator: PendingOvertimeMetricValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: PendingOvertimeMetricEngine

        init(store: any PendingOvertimeMetricStore, validator: PendingOvertimeMetricValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: PendingOvertimeMetricEngine) {
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
                throw Kit.Failure("pending overtime metric \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(PendingOvertimeMetricStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending overtime metric \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(PendingOvertimeMetricStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("pending overtime metric \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func audit(_ cutoff: Int) -> Int {
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

    static func newPendingOvertimeMetricDesk(_ store: any PendingOvertimeMetricStore, clock: any Kit.Clocks.Clock) -> PendingOvertimeMetricDesk {
        return PendingOvertimeMetricDesk(
            store: store,
            validator: defaultPendingOvertimeMetricValidator(),
            clock: clock,
            journal: [],
            engine: defaultPendingOvertimeMetricEngine()
        )
    }
}
