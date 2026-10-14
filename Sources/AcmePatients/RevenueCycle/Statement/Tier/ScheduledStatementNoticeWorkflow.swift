import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Moves scheduled statement notices through their life cycle and keeps a journal of what it did.
    final class ScheduledStatementNoticeService {
        var store: any ScheduledStatementNoticeStore
        var validator: ScheduledStatementNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ScheduledStatementNoticeEngine

        init(store: any ScheduledStatementNoticeStore, validator: ScheduledStatementNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ScheduledStatementNoticeEngine) {
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
                throw Kit.Failure("scheduled statement notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ScheduledStatementNoticeStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled statement notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ScheduledStatementNoticeStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("scheduled statement notice \(code) not found")
            }
            let result = engine.run(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func reviewStale(_ cutoff: Int) -> Int {
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

    static func newScheduledStatementNoticeService(_ store: any ScheduledStatementNoticeStore, clock: any Kit.Clocks.Clock) -> ScheduledStatementNoticeService {
        return ScheduledStatementNoticeService(
            store: store,
            validator: defaultScheduledStatementNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultScheduledStatementNoticeEngine()
        )
    }
}
