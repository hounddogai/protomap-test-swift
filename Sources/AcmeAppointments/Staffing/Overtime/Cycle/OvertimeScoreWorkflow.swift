import AcmePlatform
import Foundation

extension Staffing {
    /// Moves overtime scores through their life cycle and keeps a journal of what it did.
    final class OvertimeScoreManager {
        var store: any OvertimeScoreStore
        var validator: OvertimeScoreValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any OvertimeScoreStore, validator: OvertimeScoreValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func openValue(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime score \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OvertimeScoreStatus.inReview)
            store.save(item)
            self.note("\(code) is in review")
        }

        func complete(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime score \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OvertimeScoreStatus.archived)
            store.save(item)
            self.note("\(code) is archived: \(reason)")
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

    static func newOvertimeScoreManager(_ store: any OvertimeScoreStore, clock: any Kit.Clocks.Clock) -> OvertimeScoreManager {
        return OvertimeScoreManager(
            store: store,
            validator: defaultOvertimeScoreValidator(),
            clock: clock,
            journal: []
        )
    }
}
