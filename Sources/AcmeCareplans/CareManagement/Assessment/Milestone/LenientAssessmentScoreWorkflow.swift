import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves lenient assessment scores through their life cycle and keeps a journal of what it did.
    final class LenientAssessmentScoreDesk {
        var store: any LenientAssessmentScoreStore
        var validator: LenientAssessmentScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientAssessmentScoreStore, validator: LenientAssessmentScoreValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("lenient assessment score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientAssessmentScoreStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient assessment score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientAssessmentScoreStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newLenientAssessmentScoreDesk(_ store: any LenientAssessmentScoreStore, clock: any Kit.Clocks.Clock) -> LenientAssessmentScoreDesk {
        return LenientAssessmentScoreDesk(
            store: store,
            validator: defaultLenientAssessmentScoreValidator(),
            clock: clock,
            journal: []
        )
    }
}
