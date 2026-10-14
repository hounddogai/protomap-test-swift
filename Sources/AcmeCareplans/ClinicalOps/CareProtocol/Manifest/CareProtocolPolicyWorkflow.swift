import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves care protocol policies through their life cycle and keeps a journal of what it did.
    final class CareProtocolPolicyService {
        var store: any CareProtocolPolicyStore
        var validator: CareProtocolPolicyValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: CareProtocolPolicyEngine

        init(store: any CareProtocolPolicyStore, validator: CareProtocolPolicyValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: CareProtocolPolicyEngine) {
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
                throw Kit.Failure("care protocol policy \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(CareProtocolPolicyStatus.scheduled)
            store.save(item)
            self.note("\(code) is scheduled")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol policy \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(CareProtocolPolicyStatus.cancelled)
            store.save(item)
            self.note("\(code) is cancelled: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("care protocol policy \(code) not found")
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

    static func newCareProtocolPolicyService(_ store: any CareProtocolPolicyStore, clock: any Kit.Clocks.Clock) -> CareProtocolPolicyService {
        return CareProtocolPolicyService(
            store: store,
            validator: defaultCareProtocolPolicyValidator(),
            clock: clock,
            journal: [],
            engine: defaultCareProtocolPolicyEngine()
        )
    }
}
