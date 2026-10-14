import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves rolling assessment notices through their life cycle and keeps a journal of what it did.
    final class RollingAssessmentNoticeWorkflow {
        var store: any RollingAssessmentNoticeStore
        var validator: RollingAssessmentNoticeValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: RollingAssessmentNoticeEngine

        init(store: any RollingAssessmentNoticeStore, validator: RollingAssessmentNoticeValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: RollingAssessmentNoticeEngine) {
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
                throw Kit.Failure("rolling assessment notice \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(RollingAssessmentNoticeStatus.validated)
            store.save(item)
            self.note("\(code) is validated")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling assessment notice \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(RollingAssessmentNoticeStatus.retired)
            store.save(item)
            self.note("\(code) is retired: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("rolling assessment notice \(code) not found")
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

    static func newRollingAssessmentNoticeWorkflow(_ store: any RollingAssessmentNoticeStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> RollingAssessmentNoticeWorkflow {
        return RollingAssessmentNoticeWorkflow(
            store: store,
            validator: defaultRollingAssessmentNoticeValidator(),
            clock: clock,
            journal: [],
            engine: defaultRollingAssessmentNoticeEngine(flags)
        )
    }
}
