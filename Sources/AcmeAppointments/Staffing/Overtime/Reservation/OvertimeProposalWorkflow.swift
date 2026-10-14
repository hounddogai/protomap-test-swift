import AcmePlatform
import Foundation

extension Staffing {
    /// Moves overtime proposals through their life cycle and keeps a journal of what it did.
    final class OvertimeProposalService {
        var store: any OvertimeProposalStore
        var validator: OvertimeProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: OvertimeProposalEngine

        init(store: any OvertimeProposalStore, validator: OvertimeProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: OvertimeProposalEngine) {
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
                throw Kit.Failure("overtime proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(OvertimeProposalStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(OvertimeProposalStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("overtime proposal \(code) not found")
            }
            let result = engine.compute(item)
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

    static func newOvertimeProposalService(_ store: any OvertimeProposalStore, clock: any Kit.Clocks.Clock) -> OvertimeProposalService {
        return OvertimeProposalService(
            store: store,
            validator: defaultOvertimeProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultOvertimeProposalEngine()
        )
    }
}
