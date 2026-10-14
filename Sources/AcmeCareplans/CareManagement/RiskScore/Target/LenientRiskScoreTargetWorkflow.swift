import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves lenient risk score targets through their life cycle and keeps a journal of what it did.
    final class LenientRiskScoreTargetManager {
        var store: any LenientRiskScoreTargetStore
        var validator: LenientRiskScoreTargetValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any LenientRiskScoreTargetStore, validator: LenientRiskScoreTargetValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("lenient risk score target \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(LenientRiskScoreTargetStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("lenient risk score target \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(LenientRiskScoreTargetStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
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

    static func newLenientRiskScoreTargetManager(_ store: any LenientRiskScoreTargetStore, clock: any Kit.Clocks.Clock) -> LenientRiskScoreTargetManager {
        return LenientRiskScoreTargetManager(
            store: store,
            validator: defaultLenientRiskScoreTargetValidator(),
            clock: clock,
            journal: []
        )
    }
}
