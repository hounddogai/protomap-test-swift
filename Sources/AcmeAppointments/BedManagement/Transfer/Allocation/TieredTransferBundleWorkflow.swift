import AcmePlatform
import Foundation

extension BedManagement {
    /// Moves tiered transfer bundles through their life cycle and keeps a journal of what it did.
    final class TieredTransferBundleDesk {
        var store: any TieredTransferBundleStore
        var validator: TieredTransferBundleValidator
        var clock: any Kit.Clocks.Clock
        var journal: [String]

        init(store: any TieredTransferBundleStore, validator: TieredTransferBundleValidator, clock: any Kit.Clocks.Clock, journal: [String]) {
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
                throw Kit.Failure("tiered transfer bundle \(code) not found")
            }
            try validator.requireValid(item)
            try item.moveTo(TieredTransferBundleStatus.approved)
            store.save(item)
            self.note("\(code) is approved")
        }

        func finish(_ code: String, reason: String) throws {
            guard let item = store.find(code) else {
                throw Kit.Failure("tiered transfer bundle \(code) not found")
            }
            if item.isTerminal() {
                self.note("\(code) already closed")
                return
            }
            try item.moveTo(TieredTransferBundleStatus.withdrawn)
            store.save(item)
            self.note("\(code) is withdrawn: \(reason)")
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

    static func newTieredTransferBundleDesk(_ store: any TieredTransferBundleStore, clock: any Kit.Clocks.Clock) -> TieredTransferBundleDesk {
        return TieredTransferBundleDesk(
            store: store,
            validator: defaultTieredTransferBundleValidator(),
            clock: clock,
            journal: []
        )
    }
}
