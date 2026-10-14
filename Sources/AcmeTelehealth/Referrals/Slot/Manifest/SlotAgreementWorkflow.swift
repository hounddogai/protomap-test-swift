import AcmePlatform
import Foundation

extension Referrals {
    /// Moves slot agreements through their life cycle and keeps a journal of what it did.
    final class SlotAgreementService {
        var store: any SlotAgreementStore
        var validator: SlotAgreementValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]
        var engine: SlotAgreementEngine

        init(store: any SlotAgreementStore, validator: SlotAgreementValidator, clock: any Kit.Clocks.Clock, journal: [String], engine: SlotAgreementEngine) {
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
                throw Kit.Failure("slot agreement \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(SlotAgreementStatus.warming)
            store.save(item)
            self.note("\(code) is warming")
        }

        func retire(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot agreement \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(SlotAgreementStatus.stopped)
            store.save(item)
            self.note("\(code) is stopped: \(reason)")
        }

        func quote(_ code: String) throws -> Double {
            guard let item = store.find(code) else {
                throw Kit.Failure("slot agreement \(code) not found")
            }
            let result = engine.run(item)
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

    static func newSlotAgreementService(_ store: any SlotAgreementStore, clock: any Kit.Clocks.Clock, flags: Kit.Flags.Registry) -> SlotAgreementService {
        return SlotAgreementService(
            store: store,
            validator: defaultSlotAgreementValidator(),
            clock: clock,
            journal: [],
            engine: defaultSlotAgreementEngine(flags)
        )
    }
}
