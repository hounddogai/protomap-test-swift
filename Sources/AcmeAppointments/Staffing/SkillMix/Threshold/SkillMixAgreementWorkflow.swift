import AcmePlatform
import Foundation

extension Staffing {
    /// Moves skill mix agreements through their life cycle and keeps a journal of what it did.
    final class SkillMixAgreementService {
        var store: any SkillMixAgreementStore
        var validator: SkillMixAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any SkillMixAgreementStore, validator: SkillMixAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("skill mix agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SkillMixAgreementStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("skill mix agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SkillMixAgreementStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newSkillMixAgreementService(_ store: any SkillMixAgreementStore, clock: any Kit.Clocks.Clock) -> SkillMixAgreementService {
        return SkillMixAgreementService(
            store: store,
            validator: defaultSkillMixAgreementValidator(),
            clock: clock,
            journal: []
        )
    }
}
