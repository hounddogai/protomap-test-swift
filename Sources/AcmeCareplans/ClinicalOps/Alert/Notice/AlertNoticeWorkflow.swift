import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves alert notices through their life cycle and keeps a journal of what it did.
    final class AlertNoticeDesk {
        var store: any AlertNoticeStore
        var validator: AlertNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: AlertNoticeEngine

        init(store: any AlertNoticeStore, validator: AlertNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: AlertNoticeEngine) {
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
                throw Kit.Failure("alert notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(AlertNoticeStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(AlertNoticeStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("alert notice \(code) not found")
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

    static func newAlertNoticeDesk(_ store: any AlertNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> AlertNoticeDesk {
        return AlertNoticeDesk(
            store: store,
            validator: defaultAlertNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultAlertNoticeEngine(flags)
        )
    }
}
