import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Moves fallback care protocol ledgers through their life cycle and keeps a journal of what it did.
    final class FallbackCareProtocolLedgerService {
        var store: any FallbackCareProtocolLedgerStore
        var validator: FallbackCareProtocolLedgerValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any FallbackCareProtocolLedgerStore, validator: FallbackCareProtocolLedgerValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
            self.store = store
            self.validator = validator
            self.clock = clock
            self.journal = journal
        }

        func note(_ message: String) {
            journal.append("\(clock.now()) \(message)")
        }

        func start(_ code: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback care protocol ledger \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(FallbackCareProtocolLedgerStatus.pending)
            store.save(item)
            self.note("\(code) is pending")
        }

        func settle(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("fallback care protocol ledger \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(FallbackCareProtocolLedgerStatus.closed)
            store.save(item)
            self.note("\(code) is closed: \(reason)")
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

    static func newFallbackCareProtocolLedgerService(_ store: any FallbackCareProtocolLedgerStore, clock: any Kit.Clocks.Clock) -> FallbackCareProtocolLedgerService {
        return FallbackCareProtocolLedgerService(
            store: store,
            validator: defaultFallbackCareProtocolLedgerValidator(),
            clock: clock,
            journal: []
        )
    }
}
