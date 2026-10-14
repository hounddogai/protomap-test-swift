import AcmePlatform
import Foundation

extension Consent {
    /// Moves consent form proposals through their life cycle and keeps a journal of what it did.
    final class ConsentFormProposalManager {
        var store: any ConsentFormProposalStore
        var validator: ConsentFormProposalValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: ConsentFormProposalEngine

        init(store: any ConsentFormProposalStore, validator: ConsentFormProposalValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: ConsentFormProposalEngine) {
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
                throw Kit.Failure("consent form proposal \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(ConsentFormProposalStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func close(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form proposal \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(ConsentFormProposalStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
        }

        func score(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("consent form proposal \(code) not found")
            }
            let result = engine.price(item)
            self.note("\(code) evaluated at \(result)")
            return result
        }

        func sweep(_ cutoff: Int) -> Int {
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

    static func newConsentFormProposalManager(_ store: any ConsentFormProposalStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> ConsentFormProposalManager {
        return ConsentFormProposalManager(
            store: store,
            validator: defaultConsentFormProposalValidator(),
            clock: clock,
            journal: [],
            engine: defaultConsentFormProposalEngine(flags)
        )
    }
}
