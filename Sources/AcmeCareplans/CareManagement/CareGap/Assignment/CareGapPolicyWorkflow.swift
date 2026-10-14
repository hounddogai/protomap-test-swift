import AcmePlatform
import Foundation

extension CareManagement {
    /// Moves care gap policies through their life cycle and keeps a journal of what it did.
    final class CareGapPolicyDesk {
        var store: any CareGapPolicyStore
        var validator: CareGapPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareGapPolicyEngine

        init(store: any CareGapPolicyStore, validator: CareGapPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareGapPolicyEngine) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
            self.engine = engine
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func advance(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareGapPolicyStatus.granted)
            store.save(item)
            self.note("\(code) is granted")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareGapPolicyStatus.expired)
            store.save(item)
            self.note("\(code) is expired: \(reason)")
        }

        func estimate(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care gap policy \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newCareGapPolicyDesk(_ store: any CareGapPolicyStore, clock: any Kit.Clocks.Clock) -> CareGapPolicyDesk {
        return CareGapPolicyDesk(
            store: store,
            validator: defaultCareGapPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareGapPolicyEngine()
        )
    }
}
